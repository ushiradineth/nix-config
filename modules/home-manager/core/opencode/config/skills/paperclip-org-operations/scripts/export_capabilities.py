#!/usr/bin/env python3
"""Export reviewed local skill trees and offline Paperclip PATCH proposals."""

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
from urllib.parse import unquote


CACHES = {"node_modules", "__pycache__", ".venv", "venv", ".git", ".cache",
          ".npm", ".yarn", ".pnpm-store", ".pytest_cache", ".mypy_cache"}
SECRET_NAMES = {"credentials", "credentials.json", "secrets.json", ".netrc",
                ".npmrc", "id_rsa", "id_ed25519", "id_ecdsa", "cookies.json",
                "storage-state.json", "auth.json"}
SECRET_CONTENT = re.compile(
    rb"-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----|"
    rb"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|"
    rb"(?:AKIA|ASIA)[A-Z0-9]{16}|sk-(?:proj-)?[A-Za-z0-9_-]{24,}|"
    rb"xox[baprs]-[A-Za-z0-9-]{20,})\b|"
    rb"(?i:authorization\s*:\s*bearer\s+[A-Za-z0-9._~+/-]{12,})|"
    rb"(?i:[\"']?(?:api[_-]?key|access[_-]?token|client[_-]?secret|password)"
    rb"[\"']?\s*[:=]\s*[\"'][A-Za-z0-9_./+=-]{8,}[\"'])"
)
STATE = ".export-state.json"
RUNTIME_CONTRACT = [
    "Guidance and role proposals grant no execution, service or delegation authority.",
    "Resolve skills by semantic identity in the current inventory; generated names may be suffixed.",
    "Use engineering-quality Paperclip mapping: approved issues/checkpoints, inline review, no nested agents.",
    "Retain existing role instructions, tools, approval boundaries and pinned unrelated skills.",
]


def json_bytes(value):
    return (json.dumps(value, sort_keys=True, indent=2, ensure_ascii=False) + "\n").encode()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def parse_json(data):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError("duplicate JSON key rejected")
            result[key] = value
        return result

    return json.loads(data, object_pairs_hook=unique)


def identity(info):
    # Reading may change atime; inode/content/mode changes must still fail closed.
    return (info.st_dev, info.st_ino, info.st_mode, info.st_nlink, info.st_size,
            info.st_mtime_ns, info.st_ctime_ns)


def safe_relative(value):
    if not isinstance(value, str) or not value or any(
        not re.fullmatch(r"[A-Za-z0-9_.-]+", part) or part in {".", ".."}
        for part in value.split("/")
    ):
        raise ValueError("unsafe relative path")
    return value


def no_symlink_ancestors(path):
    for component in (*reversed(path.parents), path):
        if component.is_symlink():
            raise ValueError("symlink path rejected")


def tree(root, source_checks=False):
    """Reject links and special files before descending or reading any contents."""
    result = {}
    seen = set()

    def walk(directory):
        for path in sorted(directory.iterdir()):
            relative = safe_relative(path.relative_to(root).as_posix())
            if relative.lower() in seen:
                raise ValueError("case-colliding path")
            seen.add(relative.lower())
            mode = path.lstat()
            if stat.S_ISLNK(mode.st_mode):
                raise ValueError("symlink in tree rejected")
            if source_checks:
                name = path.name.lower()
                if name in CACHES:
                    raise ValueError("dependency cache rejected")
                if (name in SECRET_NAMES or name == ".env" or name.startswith(".env.")
                        or name.endswith((".key", ".pem", ".p12", ".pfx", ".jks"))):
                    raise ValueError("credential-bearing filename rejected")
            if stat.S_ISDIR(mode.st_mode):
                walk(path)
            elif stat.S_ISREG(mode.st_mode):
                if mode.st_nlink != 1:
                    raise ValueError("hardlink rejected")
                if mode.st_size > 16 * 1024 * 1024:
                    raise ValueError("file exceeds export size limit")
                # O_NOFOLLOW also protects the leaf between inspection and open.
                fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
                with os.fdopen(fd, "rb") as stream:
                    opened = os.fstat(stream.fileno())
                    if identity(opened) != identity(mode):
                        raise ValueError("file changed during inspection")
                    data = stream.read(16 * 1024 * 1024 + 1)
                    after = os.fstat(stream.fileno())
                    if len(data) != mode.st_size or identity(after) != identity(opened):
                        raise ValueError("file changed during read")
                if source_checks and SECRET_CONTENT.search(data):
                    raise ValueError("credential-bearing content rejected")
                result[relative] = (data, bool(mode.st_mode & 0o111))
            else:
                raise ValueError("special file rejected")

    walk(root)
    return result


def frontmatter(data, source):
    text = data.decode("utf-8")
    match = re.match(r"\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)", text, re.S)
    if not match:
        raise ValueError("missing SKILL.md frontmatter")
    fields = {}
    current = None
    for line in match[1].splitlines():
        field = re.match(r"^([a-zA-Z_-]+):\s*(.*)$", line)
        if field:
            current = field[1]
            if current in fields:
                raise ValueError("duplicate frontmatter field")
            fields[current] = field[2]
        elif line[:1].isspace() and current:
            fields[current] += " " + line.strip()
    def scalar(value):
        value = value.strip()
        if value.startswith('"'):
            try:
                return json.loads(value)
            except ValueError:
                raise ValueError("invalid quoted frontmatter text") from None
        if value.startswith("'"):
            if len(value) < 2 or not value.endswith("'"):
                raise ValueError("invalid quoted frontmatter text")
            return value[1:-1].replace("''", "'")
        if (value.lower() in {"null", "~", "true", "false"}
                or value[:1] in {"[", "{", "&", "*", "!"}
                or re.fullmatch(r"[+-]?\d+(?:\.\d+)?", value)):
            raise ValueError("frontmatter text must be a string")
        return re.sub(r"^[|>][+-]?(?:\s|$)", "", value).strip()

    name = scalar(fields.get("name", ""))
    description = scalar(fields.get("description", ""))
    if name != source or not description:
        raise ValueError("frontmatter name/description invalid")
    return description


def references(files):
    for relative, (data, _) in files.items():
        if not relative.endswith(".md"):
            continue
        text = data.decode("utf-8")
        # Fenced command examples are not package reference declarations.
        text = re.sub(r"(?ms)^```.*?^```[^\n]*$", "", text)
        links = re.findall(r"\]\(\s*<?([^\s)>]+)", text)
        links += re.findall(r"^\s*\[[^\]]+\]:\s*<?([^\s>]+)", text, re.M)
        links += [value for value in re.findall(r"`([^`\n]+)`", text)
                  if re.match(r"(?:\.?\.?/)?(?:references|scripts)/.+\.[A-Za-z0-9]+$", value)]
        for link in links:
            if re.match(r"(?:https?://|mailto:|#)", link):
                continue
            target = unquote(link.split("#", 1)[0].split("?", 1)[0])
            # The writing playbook illustrates link syntax with the literal (URL).
            if target == "URL":
                continue
            try:
                target = safe_relative(target.removeprefix("./"))
            except ValueError:
                raise ValueError("unsafe local reference") from None
            resolved = (Path(relative).parent / target).as_posix()
            if resolved not in files:
                raise ValueError("missing local reference")


def classify(root, document):
    if not isinstance(document, dict) or document.get("schema_version") != 1:
        raise ValueError("invalid manifest schema")
    entries = document.get("skills")
    if not isinstance(entries, list) or not entries:
        raise ValueError("manifest requires skills")
    sources = set()
    required = {"source", "disposition", "inclusion", "roles", "dependencies",
                "runtime_constraints", "reason"}
    for entry in entries:
        if not isinstance(entry, dict) or not required <= entry.keys():
            raise ValueError("manifest entry missing metadata")
        source = safe_relative(entry["source"])
        if "/" in source or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", source):
            raise ValueError("unsafe skill source path")
        if source in sources:
            raise ValueError("duplicate manifest source")
        sources.add(source)
        if entry["disposition"] not in {"import", "adapt", "exclude"}:
            raise ValueError("invalid manifest disposition")
        excluded = entry["disposition"] == "exclude"
        if entry["inclusion"] != ("none" if excluded else "complete-tree"):
            raise ValueError("invalid manifest inclusion")
        for field in ("roles", "dependencies", "runtime_constraints"):
            if (not isinstance(entry[field], list) or
                    any(not isinstance(v, str) or not v.strip() for v in entry[field])):
                raise ValueError("invalid manifest list")
        if (not isinstance(entry["reason"], str) or not entry["reason"].strip()
                or not entry["runtime_constraints"] or (not excluded and not entry["roles"])):
            raise ValueError("manifest requires reason, constraints and selected roles")
    discovered = set()
    for path in root.iterdir():
        if path.is_symlink():
            raise ValueError("symlink source rejected")
        if path.is_dir():
            discovered.add(path.name)
        else:
            raise ValueError("unclassified source-root file")
    if discovered != sources:
        raise ValueError("manifest coverage differs from source directories")
    selected = {entry["source"] for entry in entries if entry["disposition"] != "exclude"}
    for entry in entries:
        if any(dependency not in selected for dependency in entry["dependencies"]):
            raise ValueError("manifest dependency is not selected")
    return sorted(entries, key=lambda item: item["source"])


def inventory(root, manifest):
    manifest_bytes = manifest.read_bytes()
    if SECRET_CONTENT.search(manifest_bytes):
        raise ValueError("credential-bearing manifest rejected")
    entries = classify(root, parse_json(manifest_bytes))
    files = {}
    skills = []
    patches = []
    for entry in sorted(entries, key=lambda item: item["source"]):
        source = entry["source"]
        if entry["disposition"] == "exclude":
            continue
        source_files = tree(root / source, source_checks=True)
        if "SKILL.md" not in source_files:
            raise ValueError("selected skill missing SKILL.md")
        description = frontmatter(source_files["SKILL.md"][0], source)
        references(source_files)
        records = []
        payloads = []
        for relative, (data, executable) in sorted(source_files.items()):
            files[f"skills/{source}/{relative}"] = (data, executable)
            records.append({"path": relative, "source": f"{source}/{relative}",
                            "sha256": digest(data), "size": len(data), "executable": executable})
            try:
                content = data.decode("utf-8")
                encoding = "utf8"
            except UnicodeDecodeError:
                content = base64.b64encode(data).decode("ascii")
                encoding = "base64"
            payloads.append({"path": relative, "content": content, "encoding": encoding,
                             "executable": executable})
        skills.append({**entry, "semantic_identity": source, "description": description,
                       "files": records})
        patches.append({"semantic_identity": source, "files": payloads})
    files["ledger.json"] = (json_bytes({"schema_version": 1,
        "manifest_sha256": digest(manifest_bytes), "skills": skills,
        "dispositions": entries}), False)
    files["patches.json"] = (json_bytes({"skills": patches}), False)
    files["bindings.json"] = (json_bytes({"proposal_only": True,
        "runtime_contract": RUNTIME_CONTRACT, "capabilities": [
        {"semantic_identity": item["semantic_identity"], "roles": item["roles"],
         "dependencies": item["dependencies"], "runtime_constraints": item["runtime_constraints"]}
        for item in skills]}), False)
    return files, entries


def file_records(files):
    return {relative: {"sha256": digest(data), "executable": executable}
            for relative, (data, executable) in sorted(files.items())}


def export(output, files):
    previous = {}
    if output.exists():
        if not output.is_dir() or not (output / STATE).is_file():
            raise ValueError("existing unmanaged output rejected")
        current = tree(output)
        state = parse_json(current[STATE][0])
        if (not isinstance(state, dict) or state.get("schema_version") != 1
                or not isinstance(state.get("files"), dict)):
            raise ValueError("invalid export ownership state")
        if current[STATE] != (json_bytes(state), False):
            raise ValueError("export ownership state tampering detected")
        previous = state["files"]
        for relative in previous:
            safe_relative(relative)
            if relative == STATE:
                raise ValueError("invalid export ownership state")
        if set(current) - {STATE} != set(previous):
            raise ValueError("unmanaged or missing output files rejected")
        if file_records({k: v for k, v in current.items() if k != STATE}) != previous:
            raise ValueError("export tampering detected; output left intact")
        expected_dirs = {parent.as_posix() for name in previous
                         for parent in Path(name).parents if parent != Path(".")}
        actual_dirs = {p.relative_to(output).as_posix() for p in output.rglob("*") if p.is_dir()}
        if actual_dirs != expected_dirs:
            raise ValueError("unmanaged output directories rejected")
    state_bytes = json_bytes({"schema_version": 1, "files": file_records(files)})
    desired = {**files, STATE: (state_bytes, False)}
    if previous == file_records(files):
        return "unchanged"
    output.mkdir(mode=0o700, parents=True, exist_ok=True)
    for relative, (data, executable) in desired.items():
        path = output / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.exists() and path.read_bytes() == data and bool(path.stat().st_mode & 0o111) == executable:
            continue
        # State is written last; interrupted exports fail closed on the next attempt.
        with path.open("wb") as stream:
            stream.write(data)
        path.chmod(0o755 if executable else 0o644)
    for obsolete in sorted(set(previous) - set(files)):
        path = output / obsolete
        path.unlink()
        parent = path.parent
        while parent != output and not any(parent.iterdir()):
            parent.rmdir()
            parent = parent.parent
    return "written"


def main():
    here = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["check", "export"])
    parser.add_argument("--source-root", type=Path, default=here.parent)
    parser.add_argument("--manifest", type=Path, default=here / "capability-manifest.json")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        args.source_root = args.source_root.absolute()
        args.manifest = args.manifest.absolute()
        no_symlink_ancestors(args.source_root)
        no_symlink_ancestors(args.manifest)
        if args.output is not None:
            args.output = args.output.absolute()
            no_symlink_ancestors(args.output)
            source = args.source_root.resolve()
            output = args.output.resolve()
            if (output.is_relative_to(source) or source.is_relative_to(output)
                    or args.manifest.resolve().is_relative_to(output)):
                raise ValueError("output overlap with source or manifest rejected")
        files, entries = inventory(args.source_root, args.manifest)
        outcome = "valid"
        if args.command == "export":
            if args.output is None:
                parser.error("export requires --output")
            outcome = export(args.output, files)
        counts = ", ".join(
            f"{sum(entry['disposition'] == kind for entry in entries)} {kind}"
            for kind in ("import", "adapt", "exclude")
        )
        print(f"{args.command}: {outcome}; {len(entries)} classified directories ({counts}); "
              f"{len(files)} exported files")
        return 0
    except (ValueError, OSError, KeyError, TypeError, UnicodeError) as error:
        print(f"error: {error}" if type(error) is ValueError else
              f"error: {type(error).__name__}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
