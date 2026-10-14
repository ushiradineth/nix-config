#!/usr/bin/env python3
"""Tests use disposable source; scanner rule fixtures are never executed."""
import json
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from types import SimpleNamespace

REPO = Path(__file__).resolve().parents[1]
RUNTIME = "--runtime" in sys.argv
if RUNTIME:
    sys.argv.remove("--runtime")


def runner_module():
    spec = importlib.util.spec_from_file_location("semgrep_scan", REPO / "scripts/semgrep-scan.py")
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="semgrep-local-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.root = self.base / 'source with spaces " café'
        self.root.mkdir()
        self.config = self.base / "config"
        self.config.mkdir(mode=0o700)
        self.env = dict(os.environ, XDG_CONFIG_HOME=str(self.config))

    def scan(self, *args):
        binary = os.environ.get("SEMGREP_LOCAL_BINARY")
        command = [binary] if binary else [sys.executable, str(REPO / "scripts/semgrep-scan.py")]
        result = subprocess.run(command + ["--root", str(self.root), *args],
                                env=self.env, capture_output=True, text=True, timeout=60)
        self.assertTrue(result.stdout, result.stderr)
        return result.returncode, json.loads(result.stdout)

    def profile(self, **changes):
        directory = self.config / "semgrep/profiles/project-a"
        directory.mkdir(parents=True, mode=0o700, exist_ok=True)
        data = {"version": 1, "root": str(self.root), "rule_files": [], "exclude": []}
        data.update(changes)
        path = directory / "profile.json"
        path.write_text(json.dumps(data))
        path.chmod(0o600)
        return directory

    @unittest.skipUnless(RUNTIME, "requires actual OS confinement; use --runtime")
    def test_clean_and_findings_without_source_mutation(self):
        source = self.root / "app.js"
        source.write_text("document.body.textContent = window.location.hash;\n")
        code, report = self.scan()
        self.assertEqual(code, 0, report)
        self.assertEqual(report["status"], "clean")
        source.write_text("document.body.innerHTML = window.location.hash;\n")
        before = source.read_bytes()
        code, report = self.scan()
        self.assertEqual(code, 1, report)
        self.assertEqual(report["status"], "findings")
        self.assertEqual(report["semgrep"]["results"][0]["check_id"], "browser-url-to-html")
        self.assertEqual(source.read_bytes(), before)
        self.assertEqual(list(self.root.iterdir()), [source])

    @unittest.skipUnless(RUNTIME, "requires actual OS confinement; use --runtime")
    def test_actual_network_and_write_denial(self):
        runner = runner_module()
        workspace = self.base / "workspace"
        workspace.mkdir()
        probe = "import socket\ntry:\n socket.create_connection(('127.0.0.1',9),timeout=1)\nexcept PermissionError:\n print('DENIED')\n"
        result = runner.run_confined([sys.executable, "-c", probe], self.root, workspace)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "DENIED")
        source = self.root / "app.js"
        source.write_text("original")
        probe = "import sys\ntry:\n open(sys.argv[1],'w').write('changed')\nexcept PermissionError:\n print('DENIED')\n"
        result = runner.run_confined([sys.executable, "-c", probe, str(source)], self.root, workspace)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "DENIED")
        self.assertEqual(source.read_text(), "original")

    def test_missing_confinement_has_no_fallback(self):
        runner = runner_module()
        with mock.patch.object(runner.shutil, "which", return_value=None), mock.patch.object(runner, "SANDBOX_EXEC", "/missing/sandbox"), mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(runner.ScanError):
                runner.confined_command(["semgrep"], self.root, self.base)

    @unittest.skipUnless(RUNTIME, "requires actual OS confinement; use --runtime")
    def test_profile_addition_never_replaces_baseline(self):
        profile = self.profile(rule_files=["private.yml"])
        (profile / "private.yml").write_text('rules:\n  - id: private-call\n    languages: [javascript]\n    message: Synthetic unsafe call\n    severity: WARNING\n    pattern: forbidden($X)\n')
        (profile / "private.js").write_text('// ruleid: private-call\nforbidden(input);\n// ok: private-call\nallowed(input);\n')
        for path in profile.iterdir():
            path.chmod(0o600)
        (self.root / "app.js").write_text("document.body.innerHTML = window.location.hash;\nforbidden(input);\n")
        code, report = self.scan("--profile", "project-a")
        self.assertEqual(code, 1, report)
        self.assertEqual({r["check_id"] for r in report["semgrep"]["results"]},
                         {"browser-url-to-html", "private-call"})
        self.assertEqual(report["profile"], "project-a")

    @unittest.skipUnless(RUNTIME, "requires actual OS confinement; use --runtime")
    def test_private_report_is_exclusive_and_outside_source(self):
        (self.root / "app.js").write_text("const safe = 1;\n")
        output = self.base / "report.json"
        code, report = self.scan("--output", str(output))
        self.assertEqual(code, 0, report)
        self.assertEqual(output.stat().st_mode & 0o777, 0o600)
        self.assertEqual(json.loads(output.read_text())["status"], "clean")
        self.assertEqual(self.scan("--output", str(output))[0], 2)
        self.assertEqual(self.scan("--output", str(self.root / "report.json"))[0], 2)
        self.assertFalse((self.root / "report.json").exists())

    def test_baseline_manifest_and_annotations(self):
        runner = runner_module()
        manifest, configs = runner.load_baseline()
        self.assertEqual(len(manifest["rules"]), 11)
        self.assertEqual({l for r in manifest["rules"] for l in r["languages"]},
                         {"javascript", "typescript", "go", "rust", "python"})
        self.assertEqual(len(configs), 5)

    def test_baseline_disagreement_is_not_ignored(self):
        runner = runner_module()
        baseline = self.base / "baseline"
        shutil.copytree(REPO / "security/semgrep", baseline)
        path = baseline / "manifest.json"
        path.chmod(0o600)
        manifest = json.loads(path.read_text())
        manifest["rules"][0]["languages"] = ["python"]
        path.write_text(json.dumps(manifest))
        with mock.patch.object(runner, "BASELINE", baseline), self.assertRaises(runner.ScanError):
            runner.load_baseline()

    def test_profile_schema_binding_modes_and_ids(self):
        runner = runner_module()
        mutations = [{"version": True}, {"version": 2}, {"root": str(self.base)},
                     {"root": "relative"}, {"command": "do-not-run"}, {"rule_files": "p/python"},
                     {"exclude": ["../outside"]}, {"exclude": ["https://example.invalid"]},
                     {"rule_files": ["../outside.yml"]}, {"rule_files": ["https://example.invalid/rules.yml"]}]
        for change in mutations:
            with self.subTest(change=change):
                self.profile(**change)
                with self.assertRaises((runner.ScanError, OSError)):
                    runner.load_profile("project-a", self.root, self.config, set())
        self.profile()
        for profile_id in ("", "../project-a", "/project-a", "p/python", "missing", "--auto"):
            with self.subTest(profile_id=profile_id), self.assertRaises((runner.ScanError, OSError)):
                runner.load_profile(profile_id, self.root, self.config, set())
        path = self.profile() / "profile.json"
        path.chmod(0o644)
        with self.assertRaises(runner.ScanError):
            runner.load_profile("project-a", self.root, self.config, set())

    def test_rule_extensions_yaml_and_duplicate_keys_fail_closed(self):
        runner = runner_module()
        rule = {"id": "example", "languages": ["javascript"], "message": "Synthetic", "severity": "WARNING", "pattern": "foo($X)"}
        path = self.base / "rules.yml"
        for key in ("validators", "extends", "fix", "extract", "postprocessor", "code", "options", "paths"):
            with self.subTest(key=key):
                path.write_text(json.dumps({"rules": [dict(rule, **{key: "untrusted"})]}))
                with self.assertRaises(runner.ScanError):
                    runner.load_rules(path)
        import yaml
        for text in ('!!python/object/apply:os.system ["do-not-run"]', 'rules: []\nrules: []',
                     'rules: &x [*x]', json.dumps({"rules": [dict(rule, mode="extract")]}),
                     json.dumps({"rules": [dict(rule, patterns=[{"code": "do-not-run"}])]})):
            path.write_text(text)
            with self.subTest(text=text), self.assertRaises((runner.ScanError, yaml.YAMLError)):
                runner.load_rules(path)

    def test_profile_rule_collision_and_missing_fixtures(self):
        runner = runner_module()
        directory = self.profile(rule_files=["custom.yml"])
        path = directory / "custom.yml"
        path.write_text('rules:\n  - id: browser-url-to-html\n    languages: [javascript]\n    message: Synthetic\n    severity: WARNING\n    pattern: foo($X)\n')
        path.chmod(0o600)
        with self.assertRaises(runner.ScanError):
            runner.load_profile("project-a", self.root, self.config, {"browser-url-to-html"})
        with self.assertRaises(runner.ScanError):
            runner.load_profile("project-a", self.root, self.config, set())

    def test_private_owner_directory_and_duplicate_json_checks(self):
        runner = runner_module()
        directory = self.profile()
        with mock.patch.object(runner.os, "getuid", return_value=os.getuid() + 1), self.assertRaises(runner.ScanError):
            runner.load_profile("project-a", self.root, self.config, set())
        directory.chmod(0o755)
        with self.assertRaises(runner.ScanError):
            runner.load_profile("project-a", self.root, self.config, set())
        directory.chmod(0o700)
        (directory / "profile.json").write_text('{"version":1,"version":1}')
        with self.assertRaises(runner.ScanError):
            runner.load_profile("project-a", self.root, self.config, set())

    def test_private_rule_symlink_escape(self):
        runner = runner_module()
        directory = self.profile(rule_files=["custom.yml"])
        external = self.base / "external.yml"
        external.write_text("rules: []")
        external.chmod(0o600)
        (directory / "custom.yml").symlink_to(external)
        with self.assertRaises(runner.ScanError):
            runner.load_profile("project-a", self.root, self.config, set())

    def test_source_paths_and_empty_scopes(self):
        runner = runner_module()
        (self.root / "app.js").write_text("const safe = 1;")
        for requested in (["../outside.js"], ["/absolute.js"], ["missing.js"]):
            with self.subTest(requested=requested), self.assertRaises((runner.ScanError, OSError)):
                runner.source_files(self.root, requested)
        with self.assertRaises(runner.ScanError):
            runner.source_files(self.root, None, ["*.js"])
        (self.root / "escape.js").symlink_to(self.base / "external.js")
        with self.assertRaises(runner.ScanError):
            runner.source_files(self.root, None)

    def test_reports_reject_configuration_source_and_symlink_destinations(self):
        runner = runner_module()
        target = self.root / "app.js"
        target.write_text("original")
        link = self.base / "link"
        link.symlink_to(target)
        for path in (target, self.root / "report.json", link, self.config / "report.json",
                     REPO / "security/semgrep/report.json"):
            with self.subTest(path=path), self.assertRaises(runner.ScanError):
                runner.output_path(str(path), self.root, self.config)
        self.assertEqual(target.read_text(), "original")

    def test_engine_failures_and_incomplete_scopes_are_not_clean(self):
        runner = runner_module()
        target = self.root / "app.js"
        target.write_text("safe")
        original = {"version": "test", "results": [], "errors": [], "paths": {"scanned": [str(target)]}}
        mutations = [(2, {}), (0, {"errors": [{"type": "parse-error"}]}), (0, {"paths": {"scanned": []}}),
                     (0, {"skipped_rules": ["example"]}), (0, {"time": {"fixpoint_timeouts": ["example"]}}), (1, {})]
        manifest, _ = runner.load_baseline()
        for exit_code, change in mutations:
            with self.subTest(exit_code=exit_code, change=change):
                code, report = runner.completed_report(subprocess.CompletedProcess([], exit_code),
                                                      dict(original, **change), [target], manifest, self.root, None, [])
                self.assertEqual(code, 2)
                self.assertEqual(report["status"], "incomplete")
                self.assertEqual(report["engine_exit"], exit_code)

    def test_engine_environment_removes_ambient_overrides(self):
        runner = runner_module()
        with mock.patch.dict(os.environ, {"SEMGREP_RULES": "auto", "SEMGREP_APP_TOKEN": "synthetic",
                                         "SEMGREP_SEND_METRICS": "on", "HTTP_PROXY": "http://example.invalid"}):
            environment = runner.engine_environment(self.base)
        self.assertEqual(environment["SEMGREP_SEND_METRICS"], "off")
        self.assertNotIn("SEMGREP_RULES", environment)
        self.assertNotIn("SEMGREP_APP_TOKEN", environment)
        self.assertNotIn("HTTP_PROXY", environment)

    def test_broad_roots_and_target_local_temp_are_rejected_before_writes(self):
        runner = runner_module()
        for root in ("/", str(Path.home()), str(self.config)):
            with self.subTest(root=root), mock.patch.dict(os.environ, {"XDG_CONFIG_HOME": str(self.config)}):
                with self.assertRaises(runner.ScanError):
                    runner.scan(SimpleNamespace(root=root, files=None, profile=None, output=None))
        with mock.patch.dict(os.environ, {"TMPDIR": str(self.root)}), self.assertRaises(runner.ScanError):
            runner.scan(SimpleNamespace(root=str(self.root), files=None, profile=None, output=None))
        self.assertEqual(list(self.root.iterdir()), [])

    def test_linux_confinement_shape_without_claiming_native_execution(self):
        runner = runner_module()
        with mock.patch.object(runner.sys, "platform", "linux"), mock.patch.dict(os.environ, {"SEMGREP_LOCAL_BWRAP": "/test/bwrap"}):
            command = runner.confined_command(["semgrep"], self.root, self.base)
        self.assertIn("--unshare-net", command)
        self.assertEqual(command[command.index("--ro-bind") + 1:command.index("--ro-bind") + 3], ["/", "/"])
        self.assertIn(str(self.base), command)

    @unittest.skipUnless(RUNTIME, "requires actual OS confinement; use --runtime")
    def test_parser_failure_unknown_flags_and_zero_scope(self):
        self.assertEqual(self.scan()[0], 2)
        (self.root / "app.js").write_text("const = = !!;\n")
        code, report = self.scan()
        self.assertEqual(code, 2, report)
        self.assertEqual(report["status"], "incomplete")
        self.assertEqual(self.scan("--config", "auto")[0], 2)

    @unittest.skipUnless(RUNTIME, "requires actual OS confinement; use --runtime")
    def test_parse_controls_cover_all_five_languages_without_security_matches(self):
        previous = None
        for extension, source in ((".js", "const = = !!;"), (".ts", "const value: = ;"),
                                  (".py", "value = ("), (".go", "package main\nfunc main( {"),
                                  (".rs", "fn main( {")):
            if previous:
                previous.unlink()
            previous = self.root / ("broken" + extension)
            previous.write_text(source)
            with self.subTest(extension=extension):
                code, report = self.scan()
                self.assertEqual(code, 2, report)
                self.assertEqual(report["status"], "incomplete")

    def test_special_configuration_files_cannot_block_the_runner(self):
        runner = runner_module()
        path = self.base / "fifo.yml"
        os.mkfifo(path, 0o600)
        with self.assertRaises(runner.ScanError):
            runner.read_text(path)

    def test_temp_unavailability_has_no_source_directory_fallback(self):
        runner = runner_module()
        with mock.patch.object(runner.os, "access", return_value=False), self.assertRaises(runner.ScanError):
            runner.private_temp_parent(self.root)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_private_fixture_empty_or_failed_results_are_rejected(self):
        runner = runner_module()
        workspace = self.base / "workspace"
        workspace.mkdir()
        selected = [({"rules": [{"id": "synthetic"}]}, [(".js", "// static")])]
        for raw in ({"results": {}}, {"results": {"config": {"checks": {"synthetic": {"passed": False}}}}}):
            with self.subTest(raw=raw), mock.patch.object(runner, "run_confined", return_value=subprocess.CompletedProcess([], 0, json.dumps(raw), "")):
                with self.assertRaises(runner.ScanError):
                    runner.profile_tests("semgrep", selected, self.root, workspace)


if __name__ == "__main__":
    unittest.main()
