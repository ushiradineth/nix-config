#!/usr/bin/env python3
"""Confined, local-only static scanning. No project code is executed."""
import argparse
from collections import Counter
import fnmatch
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import stat
import tempfile

import yaml

BASELINE = Path(os.environ.get("SEMGREP_LOCAL_BASELINE", Path(__file__).resolve().parents[1] / "security/semgrep")).resolve()
SANDBOX_EXEC = "/usr/bin/sandbox-exec"
EXTENSIONS = {".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx", ".mts", ".cts", ".py", ".go", ".rs"}
IGNORE_DIRS = {".git", ".direnv", ".next", ".nuxt", ".cache", "node_modules", ".venv", "venv",
               "build", "dist", "target", "coverage", "__pycache__"}
FLAGS = ["--strict", "--error", "--metrics=off", "--disable-version-check", "--disable-nosem",
         "--no-rewrite-rule-ids", "--oss-only", "--no-trace", "--no-secrets-validation"]
LANGUAGES = {"javascript", "typescript", "python", "go", "rust"}
RULE_KEYS = {"id", "languages", "message", "severity", "metadata", "mode", "pattern", "patterns",
             "pattern-either", "pattern-regex", "pattern-sources", "pattern-sinks", "pattern-sanitizers",
             "pattern-propagators"}
PATTERN_KEYS = {"pattern", "patterns", "pattern-either", "pattern-inside", "pattern-not-inside", "pattern-not",
                "pattern-regex", "pattern-not-regex", "metavariable-regex", "metavariable-pattern",
                "metavariable-comparison", "focus-metavariable", "metavariable", "regex", "language",
                "comparison", "strip", "base", "exact", "by-side-effect", "label", "requires", "from", "to"}
FIXTURE_EXTENSIONS = {"javascript": [".js", ".jsx", ".ts", ".tsx"], "typescript": [".ts", ".tsx"],
                      "python": [".py"], "go": [".go"], "rust": [".rs"]}


class ScanError(Exception):
    pass


class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise ScanError(message)


def unique_pairs(pairs):
    result = {}
    for key, value in pairs:
        if not isinstance(key, str) or key in result:
            raise ScanError("duplicate or non-string configuration key")
        result[key] = value
    return result


class LocalLoader(yaml.SafeLoader):
    pass


def yaml_mapping(loader, node):
    return unique_pairs([(loader.construct_object(k), loader.construct_object(v)) for k, v in node.value])


LocalLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, yaml_mapping)


def read_text(path):
    info = path.stat()
    if not stat.S_ISREG(info.st_mode):
        raise ScanError("configuration and fixtures must be regular files")
    if info.st_size > 262144:
        raise ScanError("configuration or fixture exceeds local size limit")
    return path.read_text(encoding="utf-8")


def bounded_tree(value, depth=0, budget=None):
    budget = [10000] if budget is None else budget
    budget[0] -= 1
    if depth > 40 or budget[0] < 0:
        raise ScanError("configuration exceeds local complexity limit")
    if isinstance(value, dict):
        for key, child in value.items():
            if not isinstance(key, str):
                raise ScanError("non-string configuration key")
            bounded_tree(child, depth + 1, budget)
    elif isinstance(value, list):
        for child in value:
            bounded_tree(child, depth + 1, budget)
    elif not isinstance(value, (str, bool, int, float, type(None))):
        raise ScanError("unsupported configuration value")


def pattern_tree(value):
    if isinstance(value, dict):
        if set(value) - PATTERN_KEYS:
            raise ScanError("unsupported or executable rule extension")
        for child in value.values():
            pattern_tree(child)
    elif isinstance(value, list):
        for child in value:
            pattern_tree(child)


def load_rules(path):
    data = yaml.load(read_text(path), Loader=LocalLoader)
    bounded_tree(data)
    if not isinstance(data, dict) or set(data) != {"rules"} or not isinstance(data["rules"], list) or not data["rules"]:
        raise ScanError("local configuration must contain a nonempty rules list only")
    for rule in data["rules"]:
        if not isinstance(rule, dict) or set(rule) - RULE_KEYS or not {"id", "languages", "message", "severity"} <= set(rule):
            raise ScanError("unsupported local rule schema")
        if not isinstance(rule["id"], str) or not re.fullmatch(r"[a-z0-9][a-z0-9_.-]{0,127}", rule["id"]):
            raise ScanError("invalid local rule ID")
        if (not isinstance(rule["languages"], list) or not rule["languages"]
                or any(language not in LANGUAGES for language in rule["languages"])
                or rule["severity"] not in {"ERROR", "WARNING", "INFO"}
                or not isinstance(rule["message"], str) or not rule["message"]):
            raise ScanError("invalid language, message or severity")
        mode = rule.get("mode", "search")
        if mode not in {"search", "taint"}:
            raise ScanError("unsupported rule mode")
        matchers = set(rule) - {"id", "languages", "message", "severity", "metadata", "mode"}
        if not matchers or (mode == "taint" and not {"pattern-sources", "pattern-sinks"} <= matchers):
            raise ScanError("rule has no complete matcher")
        for key in matchers:
            pattern_tree(rule[key])
    if len({r["id"] for r in data["rules"]}) != len(data["rules"]):
        raise ScanError("duplicate local rule IDs")
    return data


def fixtures_for(config, rules, minimum=1):
    languages = {language for rule in rules for language in rule["languages"]}
    extensions = {ext for language in languages for ext in FIXTURE_EXTENSIONS[language]}
    fixtures = sorted(config.with_suffix(ext) for ext in extensions if config.with_suffix(ext).is_file())
    counts = Counter()
    for fixture in fixtures:
        for kind, rule_id in re.findall(r"(?m)^\s*(?://|#)\s*(ruleid|ok):\s*([a-z0-9_.-]+)\s*$", read_text(fixture)):
            counts[kind, rule_id] += 1
    for rule in rules:
        if any(counts[kind, rule["id"]] < minimum for kind in ("ruleid", "ok")):
            raise ScanError("every rule needs paired unsafe and safe fixture annotations")
    if any(rule_id not in {rule["id"] for rule in rules} for _, rule_id in counts):
        raise ScanError("fixture names an unknown rule")
    return fixtures


def inside(path, parent):
    return path == parent or parent in path.parents


def safe_relative(value, parent):
    path = Path(value)
    if path.is_absolute() or ".." in path.parts or not value or value.startswith("-"):
        raise ScanError("expected a relative local path")
    resolved = (parent / path).resolve(strict=True)
    if not inside(resolved, parent):
        raise ScanError("path escapes its source directory")
    return resolved


def load_baseline():
    manifest = json.loads(read_text(BASELINE / "manifest.json"), object_pairs_hook=unique_pairs)
    if (set(manifest) != {"version", "baseline_id", "rules"} or manifest.get("version") != 1
            or not isinstance(manifest.get("baseline_id"), str) or not isinstance(manifest.get("rules"), list)
            or not manifest["rules"]):
        raise ScanError("missing baseline manifest")
    ids = [entry["id"] for entry in manifest["rules"]]
    if len(ids) != len(set(ids)):
        raise ScanError("duplicate manifest rule IDs")
    configs = sorted({safe_relative(entry["file"], BASELINE) for entry in manifest["rules"]})
    actual = {}
    for config in configs:
        if config.suffix != ".yml":
            raise ScanError("baseline configuration must be local YAML")
        data = load_rules(config)
        fixtures_for(config, data["rules"], minimum=2)
        for rule in data["rules"]:
            if rule["id"] in actual:
                raise ScanError("duplicate baseline rule ID")
            actual[rule["id"]] = (config.name, rule["languages"])
    if set(actual) != set(ids) or set(BASELINE.glob("*.yml")) != set(configs):
        raise ScanError("manifest and rule IDs disagree")
    for entry in manifest["rules"]:
        if (set(entry) != {"id", "file", "languages", "family", "confidence", "blind_spots"}
                or actual[entry["id"]] != (entry["file"], entry["languages"])
                or entry["confidence"] not in {"HIGH", "MEDIUM", "LOW"}
                or not isinstance(entry["family"], str) or not entry["family"]
                or not isinstance(entry["blind_spots"], list) or not entry["blind_spots"]
                or any(not isinstance(spot, str) or not spot for spot in entry["blind_spots"])):
            raise ScanError("invalid baseline coverage metadata")
    return manifest, configs


def private_path(path, directory=False):
    info = path.stat()
    expected = 0o700 if directory else 0o600
    correct_type = stat.S_ISDIR(info.st_mode) if directory else stat.S_ISREG(info.st_mode)
    if not correct_type or info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != expected:
        raise ScanError("private profile paths must be user-owned with directory 0700/file 0600 modes")


def load_profile(profile_id, root, config_home, baseline_ids):
    if profile_id is None:
        return [], []
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,63}", profile_id):
        raise ScanError("profile ID must be a local slug")
    profiles = config_home / "semgrep/profiles"
    directory = safe_relative(profile_id, profiles)
    private_path(directory, directory=True)
    profile_file = safe_relative("profile.json", directory)
    private_path(profile_file)
    data = json.loads(read_text(profile_file), object_pairs_hook=unique_pairs)
    if (not isinstance(data, dict) or set(data) != {"version", "root", "rule_files", "exclude"}
            or type(data["version"]) is not int or data["version"] != 1 or not isinstance(data["root"], str)
            or not Path(data["root"]).is_absolute() or Path(data["root"]).resolve(strict=True) != root):
        raise ScanError("profile schema or canonical project binding is invalid")
    for key in ("rule_files", "exclude"):
        if not isinstance(data[key], list) or any(not isinstance(v, str) or not v for v in data[key]):
            raise ScanError("profile rules and exclusions must be local string arrays")
    if len(data["rule_files"]) > 20 or len(data["exclude"]) > 100:
        raise ScanError("profile exceeds local limits")
    for value in data["exclude"]:
        if value.startswith(("/", "-")) or ".." in Path(value).parts or "://" in value or "\x00" in value:
            raise ScanError("profile exclusions must be relative globs")
    selected = []
    ids = set(baseline_ids)
    for value in data["rule_files"]:
        config = safe_relative(value, directory)
        if config.suffix != ".yml":
            raise ScanError("profile rules must be local YAML files")
        for parent in config.parents:
            if not inside(parent, directory):
                break
            private_path(parent, directory=True)
        private_path(config)
        rules = load_rules(config)
        for rule in rules["rules"]:
            if rule["id"] in ids:
                raise ScanError("profile duplicates or replaces an existing rule ID")
            ids.add(rule["id"])
        fixtures = fixtures_for(config, rules["rules"])
        copied = []
        for fixture in fixtures:
            resolved = safe_relative(str(fixture.relative_to(directory)), directory)
            private_path(resolved)
            copied.append((fixture.suffix, read_text(resolved)))
        selected.append((rules, copied))
    return selected, data["exclude"]


def source_files(root, requested, exclude=None):
    if requested:
        paths = [safe_relative(value, root) for value in requested]
    else:
        paths = []
        for directory, dirs, files in os.walk(root, followlinks=False):
            dirs[:] = sorted(d for d in dirs if d not in IGNORE_DIRS)
            for name in dirs + files:
                link = Path(directory) / name
                if link.is_symlink() and not inside(link.resolve(), root):
                    raise ScanError("source symlink escapes root")
            paths.extend(Path(directory) / f for f in files if Path(f).suffix in EXTENSIONS)
    paths = [p for p in paths if not any(fnmatch.fnmatch(str(p.relative_to(root)), pattern)
                                       for pattern in (exclude or []))]
    if not paths or any(not p.is_file() or p.suffix not in EXTENSIONS for p in paths):
        raise ScanError("no eligible source files, or unsupported requested files")
    return sorted(set(p.resolve(strict=True) for p in paths))


def confined_command(command, root, workspace):
    if sys.platform == "darwin":
        if not Path(SANDBOX_EXEC).is_file():
            raise ScanError("source/network confinement is unavailable")
        # JSON string escaping is also valid for SBPL strings; never interpolate raw paths.
        policy = f'(version 1) (allow default) (deny network*) (deny file-write* (subpath {json.dumps(str(root), ensure_ascii=False)}))'
        return [SANDBOX_EXEC, "-p", policy, *command]
    if sys.platform.startswith("linux"):
        bwrap = os.environ.get("SEMGREP_LOCAL_BWRAP") or shutil.which("bwrap")
        if not bwrap:
            raise ScanError("source/network confinement is unavailable")
        return [bwrap, "--die-with-parent", "--new-session", "--unshare-net", "--ro-bind", "/", "/",
                "--bind", str(workspace), str(workspace), "--proc", "/proc", "--dev", "/dev",
                "--chdir", str(workspace), *command]
    raise ScanError("unsupported confinement platform")


def engine_environment(workspace):
    trusted_path = os.environ.get("SEMGREP_LOCAL_PATH", f"{Path(sys.executable).parent}:/usr/bin:/bin")
    environment = {"PATH": trusted_path, "HOME": str(workspace),
            "XDG_CONFIG_HOME": str(workspace / "config"), "XDG_CACHE_HOME": str(workspace / "cache"),
            "TMPDIR": str(workspace), "SEMGREP_SETTINGS_FILE": str(workspace / "settings.yml"),
            "CI": "true", "SEMGREP_SEND_METRICS": "off", "SEMGREP_ENABLE_VERSION_CHECK": "0",
            "PYTHONDONTWRITEBYTECODE": "1", "LANG": "en_US.UTF-8", "GIT_TERMINAL_PROMPT": "0",
            "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": str(workspace / "gitconfig"),
            "GIT_CONFIG_COUNT": "2", "GIT_CONFIG_KEY_0": "core.fsmonitor", "GIT_CONFIG_VALUE_0": "false",
            "GIT_CONFIG_KEY_1": "core.hooksPath", "GIT_CONFIG_VALUE_1": str(workspace / "no-hooks")}
    if os.environ.get("SEMGREP_LOCAL_CA"):
        environment["SSL_CERT_FILE"] = os.environ["SEMGREP_LOCAL_CA"]
        environment["NIX_SSL_CERT_FILE"] = os.environ["SEMGREP_LOCAL_CA"]
    return environment


def run_confined(command, root, workspace):
    return subprocess.run(confined_command(command, root, workspace), cwd=workspace,
                          env=engine_environment(workspace), stdin=subprocess.DEVNULL,
                          capture_output=True, text=True, timeout=180)


def private_temp_parent(root):
    candidates = [os.environ[name] for name in ("TMPDIR", "TMP", "TEMP") if os.environ.get(name)]
    candidates.extend(["/tmp", "/var/tmp", "/usr/tmp"])
    for candidate in candidates:
        parent = Path(candidate).resolve()
        if not inside(parent, root) and parent.is_dir() and os.access(parent, os.W_OK | os.X_OK):
            return parent
    raise ScanError("no private temporary storage outside source is available")


def output_path(value, root, config_home):
    if not value:
        return None
    path = Path(value).absolute()
    parent = path.parent.resolve(strict=True)
    resolved = parent / path.name
    if (any(inside(resolved.resolve(), protected) for protected in (root, config_home, BASELINE))
            or resolved.exists() or resolved.is_symlink()):
        raise ScanError("report must be a new file outside source, private configuration and baseline")
    return resolved


def profile_tests(engine, selected, root, workspace):
    configs = []
    for index, (data, fixtures) in enumerate(selected):
        config = workspace / f"private-{index}.yml"
        config.write_text(yaml.safe_dump(data))
        config.chmod(0o600)
        copied = []
        for extension, text in fixtures:
            fixture = config.with_suffix(extension)
            fixture.write_text(text)
            fixture.chmod(0o600)
            copied.append(str(fixture))
        result = run_confined([engine, "scan", "--test", *FLAGS, "--json", "--config", str(config), *copied], root, workspace)
        try:
            raw = json.loads(result.stdout)
        except ValueError as exc:
            raise ScanError("private fixture test did not return JSON") from exc
        checks = {rule_id: check for entry in raw.get("results", {}).values()
                  for rule_id, check in entry.get("checks", {}).items()}
        if (result.returncode != 0 or raw.get("config_missing_tests") or raw.get("config_with_errors")
                or set(checks) != {r["id"] for r in data["rules"]}
                or any(c.get("passed") is not True or c.get("errors") for c in checks.values())):
            raise ScanError("private rule fixtures failed or did not exercise every selected rule")
        configs.append(config)
    return configs


def parser_controls(workspace):
    # No literal prefilter: force AST parsing even when security rules select no file.
    # The negative lookahead never matches, so these controls cannot emit findings.
    path = workspace / "parse-controls.yml"
    path.write_text(yaml.safe_dump({"rules": [
        {"id": f"__local_parse_{language}", "languages": [language], "message": "Internal parse control",
         "severity": "INFO", "patterns": [{"pattern": "$X"},
             {"metavariable-regex": {"metavariable": "$X", "regex": "(?!)"}}]}
        for language in sorted(LANGUAGES)]}))
    path.chmod(0o600)
    return path


def completed_report(result, raw, targets, manifest, root, profile, exclude):
    if (not isinstance(raw, dict) or not isinstance(raw.get("paths"), dict)
            or not isinstance(raw["paths"].get("scanned"), list)
            or any(not isinstance(path, str) for path in raw["paths"]["scanned"])
            or not isinstance(raw.get("time", {}), dict)):
        raise ScanError(f"invalid engine report (exit {result.returncode})")
    scanned = {Path(p).resolve() for p in raw.get("paths", {}).get("scanned", [])}
    incomplete = (result.returncode not in (0, 1) or raw.get("errors") or raw.get("skipped_rules")
                  or scanned != set(targets) or raw.get("time", {}).get("fixpoint_timeouts")
                  or not isinstance(raw.get("version"), str) or not isinstance(raw.get("results"), list)
                  or (result.returncode == 1 and not raw["results"]))
    status = "incomplete" if incomplete else "findings" if raw["results"] else "clean"
    report = {"status": status, "engine_version": raw.get("version"), "engine_exit": result.returncode,
              "root": str(root), "baseline": manifest, "profile": profile,
              "exclusions": {"directories": sorted(IGNORE_DIRS), "profile": exclude},
              "coverage": {"languages": sorted({l for rule in manifest["rules"] for l in rule["languages"]}),
                           "limits": "Bounded syntactic/intraprocedural candidates only; other languages/categories are unsupported."},
              "scanned_paths": sorted(str(p) for p in scanned), "semgrep": raw}
    return (2 if incomplete else 1 if status == "findings" else 0), report


def scan(args):
    if not args.root:
        raise ScanError("root cannot be empty")
    root = Path(args.root).resolve(strict=True)
    home = Path.home().resolve()
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config")).resolve()
    system_temp_roots = {Path(p).resolve() for p in ("/tmp", "/var/tmp", "/usr/tmp")}
    if not root.is_dir() or root in system_temp_roots or inside(home, root) or inside(config_home, root):
        raise ScanError("root must be a narrow source directory outside private runtime/config state")
    for name in ("TMPDIR", "TMP", "TEMP"):
        if os.environ.get(name) and inside(Path(os.environ[name]).resolve(), root):
            raise ScanError("temporary storage cannot be inside source")
    manifest, configs = load_baseline()
    selected, exclude = load_profile(args.profile, root, config_home, {r["id"] for r in manifest["rules"]})
    targets = source_files(root, args.files, exclude)
    destination = output_path(args.output, root, config_home)
    engine = os.environ.get("SEMGREP_LOCAL_ENGINE") or shutil.which("semgrep")
    if not engine:
        raise ScanError("Semgrep engine is unavailable")
    if inside(Path(engine).resolve(strict=True), root):
        raise ScanError("scanner executable cannot come from the target source")
    with tempfile.TemporaryDirectory(prefix="semgrep-local-", dir=private_temp_parent(root)) as temp:
        workspace = Path(temp).resolve()
        if inside(workspace, root):
            raise ScanError("temporary storage cannot be inside source")
        private_configs = profile_tests(engine, selected, root, workspace)
        command = [engine, "scan", *FLAGS, "--json"]
        for config in [*configs, *private_configs, parser_controls(workspace)]:
            command.extend(["--config", str(config)])
        result = run_confined(command + [str(p) for p in targets], root, workspace)
        try:
            raw = json.loads(result.stdout)
        except ValueError as exc:
            raise ScanError(f"confined engine failed without JSON (exit {result.returncode})") from exc
    code, report = completed_report(result, raw, targets, manifest, root, args.profile, exclude)
    if destination:
        # Revalidate after the engine run; exclusive creation also rejects late symlinks.
        destination = output_path(str(destination), root, config_home)
        assert destination is not None
        fd = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, "w") as stream:
            json.dump(report, stream)
    return code, report


def main():
    try:
        parser = Parser(description=__doc__)
        parser.add_argument("--root", required=True)
        parser.add_argument("--files", nargs="+")
        parser.add_argument("--profile")
        parser.add_argument("--output")
        args = parser.parse_args()
        code, report = scan(args)
    except (ScanError, OSError, ValueError, KeyError, TypeError, yaml.YAMLError, subprocess.TimeoutExpired) as exc:
        code, report = 2, {"status": "error", "error": str(exc)}
    print(json.dumps(report))
    return code


if __name__ == "__main__":
    sys.exit(main())
