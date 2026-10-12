"""Public CLI tests with disposable fixtures and repository-byte readback; no live services."""

import base64
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / (
    "modules/home-manager/core/opencode/config/skills/"
    "paperclip-org-operations/scripts/export_capabilities.py"
)


class CapabilitiesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.source = self.root / "source"
        self.skill = self.source / "example"
        self.skill.mkdir(parents=True)
        (self.skill / "SKILL.md").write_text(
            "---\nname: example\ndescription: Fixture guidance.\n---\n\nRead `references/note.md`.\n"
        )
        (self.skill / "references").mkdir()
        (self.skill / "references/note.md").write_text("Fixture reference.\n")
        self.manifest = self.root / "manifest.json"
        self.entries = [{
            "source": "example", "disposition": "import", "inclusion": "complete-tree",
            "roles": ["coding"], "dependencies": [],
            "runtime_constraints": ["Guidance grants no tool access."],
            "reason": "Reusable fixture guidance.",
        }]
        self.save_manifest()
        self.output = self.root / "export"

    def save_manifest(self):
        self.manifest.write_text(json.dumps({"schema_version": 1, "skills": self.entries}))

    def cli(self, command="check", *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT), command, "--source-root", str(self.source),
             "--manifest", str(self.manifest), *args],
            capture_output=True, text=True, timeout=20,
        )

    def export(self):
        return self.cli("export", "--output", str(self.output))

    def test_export_preserves_complete_tree_bytes_license_and_execution(self):
        binary = b"\x00\xff\x80\r\n"
        (self.skill / "image.bin").write_bytes(binary)
        executable = self.skill / "run.sh"
        executable.write_text("#!/bin/sh\nexit 0\n")
        executable.chmod(0o755)
        (self.skill / "LICENSE").write_text("Fixture license.\n")
        result = self.export()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.output / "skills/example/image.bin").read_bytes(), binary)
        self.assertEqual((self.output / "skills/example/LICENSE").read_text(), "Fixture license.\n")
        self.assertTrue((self.output / "skills/example/run.sh").stat().st_mode & stat.S_IXUSR)
        proposals = json.loads((self.output / "patches.json").read_text())
        files = {f["path"]: f for f in proposals["skills"][0]["files"]}
        self.assertEqual(files["image.bin"]["encoding"], "base64")
        self.assertEqual(base64.b64decode(files["image.bin"]["content"]), binary)
        self.assertTrue(files["run.sh"]["executable"])

    def test_unclassified_directory_rejected_before_output(self):
        (self.source / "new-skill").mkdir()
        result = self.export()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("coverage", result.stderr)
        self.assertFalse(self.output.exists())

    def assert_rejected(self, needle):
        result = self.export()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(needle, result.stderr)
        self.assertFalse(self.output.exists())

    def test_missing_classified_skill(self):
        self.entries[0]["source"] = "missing"
        self.save_manifest()
        self.assert_rejected("coverage")

    def test_manifest_path_and_duplicate_rejection(self):
        for source in ("../example", "/example", "example/../example", "example\\child"):
            with self.subTest(source=source):
                self.entries[0]["source"] = source
                self.save_manifest()
                self.assert_rejected("path")
        self.entries[0]["source"] = "example"
        self.entries.append(dict(self.entries[0]))
        self.save_manifest()
        self.assert_rejected("duplicate")

    def test_manifest_requires_disposition_metadata(self):
        for field in ("roles", "dependencies", "reason", "runtime_constraints", "inclusion"):
            with self.subTest(field=field):
                old = self.entries[0].pop(field)
                self.save_manifest()
                self.assert_rejected("manifest")
                self.entries[0][field] = old

    def test_empty_directories_must_be_excluded(self):
        empty = self.source / "empty"
        empty.mkdir()
        self.entries.append({**self.entries[0], "source": "empty"})
        self.save_manifest()
        self.assert_rejected("SKILL.md")
        self.entries[-1].update(disposition="exclude", inclusion="none", roles=[],
                                reason="Empty placeholder, no procedure to import.")
        self.save_manifest()
        result = self.export()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.output / "skills/empty").exists())

    def test_frontmatter_validation(self):
        for text in ("No header", "---\nname: wrong\ndescription: Good.\n---\n",
                     "---\nname: example\ndescription:\n---\n",
                     "---\nname: example\ndescription: null\n---\n",
                     "---\nname: example\ndescription: []\n---\n",
                     '---\nname: example\ndescription: "Unclosed description\n---\n',
                     "---\nname: example\ndescription: 123\n---\n",
                     "---\nname: example\nname: example\ndescription: Good.\n---\n"):
            with self.subTest(text=text):
                (self.skill / "SKILL.md").write_text(text)
                self.assert_rejected("frontmatter")

    def test_local_references_and_traversal(self):
        for target in ("references/missing.md", "LICENSE", "../outside.md", "%2e%2e/outside.md",
                       "/private/file.md", "references\\note.md"):
            with self.subTest(target=target):
                (self.skill / "references/note.md").write_text(f"Read [guide]({target}).\n")
                self.assert_rejected("reference")

    def test_escaping_and_internal_symlinks_rejected(self):
        outside = self.root / "outside.md"
        outside.write_text("Unrelated data.\n")
        link = self.skill / "link.md"
        for target in (outside, self.skill / "SKILL.md"):
            with self.subTest(target=target.name):
                link.symlink_to(target)
                self.assert_rejected("symlink")
                link.unlink()
        directory = self.source / "linked"
        directory.symlink_to(self.skill, target_is_directory=True)
        self.assert_rejected("symlink")

    def test_dependency_caches_and_credentials_rejected(self):
        for name in ("node_modules", "__pycache__", ".venv", ".git", ".cache"):
            with self.subTest(name=name):
                path = self.skill / name
                path.mkdir()
                self.assert_rejected("cache")
                path.rmdir()
        for name in (".env", "credentials.json", "id_ed25519", "private.key"):
            with self.subTest(name=name):
                path = self.skill / name
                path.write_text("Not a real credential.\n")
                self.assert_rejected("credential")
                path.unlink()
        for content in ("-----BEGIN PRIVATE KEY-----\nfixture\n",
                        "ghp_" + "a" * 36, "AKIA" + "A" * 16,
                        'api_key = "supersecret"',
                        'api_key = "fixture-sensitive-value-123456789"',
                        'Authorization: Bearer fixture-sensitive-value-123456789'):
            with self.subTest(content=content[:12]):
                path = self.skill / "note.txt"
                path.write_text(content)
                self.assert_rejected("credential")
                self.assertNotIn(content, self.export().stderr)
                path.unlink()

    def test_special_files_rejected_without_opening(self):
        os.mkfifo(self.skill / "pipe")
        self.assert_rejected("special file")

    def test_valid_folded_frontmatter_and_external_links(self):
        (self.skill / "SKILL.md").write_text(
            "---\nname: example\ndescription: |\n  Use fixture guidance.\n  Preserve facts.\n---\n"
            "Read [guide](references/note.md#section) and [docs](https://example.org/docs).\n"
        )
        result = self.cli()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.output.exists())

    def test_dependency_must_be_selected(self):
        self.entries[0]["dependencies"] = ["absent"]
        self.save_manifest()
        self.assert_rejected("dependency")

    def snapshot(self):
        return {p.relative_to(self.output).as_posix():
                (p.read_bytes(), p.stat().st_mode & 0o777, p.stat().st_mtime_ns)
                for p in self.output.rglob("*") if p.is_file()}

    def test_noop_stability_decoded_hashes_and_source_update(self):
        (self.skill / "image.bin").write_bytes(b"\xff\x00")
        result = self.export()
        self.assertEqual(result.returncode, 0, result.stderr)
        before = self.snapshot()
        result = self.export()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(before, self.snapshot())
        ledger = json.loads((self.output / "ledger.json").read_text())
        record = next(f for f in ledger["skills"][0]["files"] if f["path"] == "image.bin")
        self.assertEqual(record["sha256"], hashlib.sha256(b"\xff\x00").hexdigest())
        self.assertNotIn(str(self.root), (self.output / "ledger.json").read_text())
        (self.skill / "references/note.md").write_text("Updated guidance.\n")
        (self.skill / "image.bin").unlink()
        result = self.export()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.output / "skills/example/image.bin").exists())
        self.assertEqual((self.output / "skills/example/references/note.md").read_text(),
                         "Updated guidance.\n")

    def test_existing_unmanaged_output_rejected(self):
        self.output.mkdir()
        result = self.export()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unmanaged", result.stderr)
        self.assertEqual(list(self.output.iterdir()), [])

    def test_noncanonical_ownership_state_rejected(self):
        self.assertEqual(self.export().returncode, 0)
        state = self.output / ".export-state.json"
        state.write_bytes(state.read_bytes() + b"\n")
        self.assertIn("tampering", self.export().stderr)

    def test_duplicate_json_keys_rejected(self):
        text = self.manifest.read_text()
        self.manifest.write_text(text.replace('"schema_version": 1',
                                             '"schema_version": 9, "schema_version": 1'))
        self.assert_rejected("duplicate")

    def test_output_tampering_and_unrelated_files_preserved(self):
        self.assertEqual(self.export().returncode, 0)
        path = self.output / "skills/example/SKILL.md"
        original = path.read_bytes()
        path.write_text("User changed exported content.\n")
        result = self.export()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("tampering", result.stderr)
        self.assertEqual(path.read_text(), "User changed exported content.\n")
        path.write_bytes(original)
        path.chmod(0o755)
        self.assertIn("tampering", self.export().stderr)
        path.chmod(0o644)
        unrelated = self.output / "user.txt"
        unrelated.write_text("User work.\n")
        self.assertIn("unmanaged", self.export().stderr)
        self.assertEqual(unrelated.read_text(), "User work.\n")

    def test_output_source_overlap_and_symlink_ancestors(self):
        for output in (self.source, self.skill / "export", self.root):
            with self.subTest(output=output.name):
                result = self.cli("export", "--output", str(output))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("overlap", result.stderr)
        linked = self.root / "linked"
        real = self.root / "real"
        real.mkdir()
        linked.symlink_to(real, target_is_directory=True)
        for output in (linked, linked / "export"):
            with self.subTest(output=str(output)):
                result = self.cli("export", "--output", str(output))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("symlink", result.stderr)
        self.assertEqual(list(real.iterdir()), [])

    def test_output_symlink_and_hardlink_rejected(self):
        self.assertEqual(self.export().returncode, 0)
        path = self.output / "skills/example/SKILL.md"
        original = path.read_bytes()
        path.unlink()
        path.symlink_to(self.skill / "SKILL.md")
        self.assertIn("symlink", self.export().stderr)
        path.unlink()
        path.write_bytes(original)
        (self.root / "hardlink").hardlink_to(path)
        self.assertIn("hardlink", self.export().stderr)


class RepositoryExportTest(unittest.TestCase):
    def test_repository_export_matches_manifest_and_all_source_bytes(self):
        source = SCRIPT.parents[2]
        manifest = json.loads((SCRIPT.parents[1] / "capability-manifest.json").read_text())
        entries = {entry["source"]: entry for entry in manifest["skills"]}
        self.assertEqual(set(entries), {p.name for p in source.iterdir() if p.is_dir()})
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp).resolve() / "export"
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "export", "--output", str(output)],
                capture_output=True, text=True, timeout=20,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            ledger = json.loads((output / "ledger.json").read_text())
            patches = json.loads((output / "patches.json").read_text())
            by_identity = {item["semantic_identity"]: item for item in ledger["skills"]}
            payloads = {item["semantic_identity"]: item for item in patches["skills"]}
            selected = {name for name, entry in entries.items() if entry["disposition"] != "exclude"}
            self.assertEqual(set(by_identity), selected)
            self.assertEqual(set(payloads), selected)
            for name in sorted(selected):
                expected = {p.relative_to(source / name).as_posix(): p
                            for p in (source / name).rglob("*") if p.is_file()}
                records = {record["path"]: record for record in by_identity[name]["files"]}
                proposed = {item["path"]: item for item in payloads[name]["files"]}
                self.assertEqual(set(records), set(expected))
                self.assertEqual(set(proposed), set(expected))
                for relative, path in expected.items():
                    original = path.read_bytes()
                    exported = output / "skills" / name / relative
                    self.assertTrue(exported.read_bytes() == original,
                                    f"byte mismatch: {name}/{relative}")
                    executable = bool(path.stat().st_mode & 0o111)
                    self.assertEqual(bool(exported.stat().st_mode & 0o111), executable)
                    self.assertEqual(records[relative]["sha256"], hashlib.sha256(original).hexdigest())
                    self.assertEqual(records[relative]["size"], len(original))
                    self.assertEqual(records[relative]["executable"], executable)
                    patch = proposed[relative]
                    decoded = (base64.b64decode(patch["content"], validate=True)
                               if patch["encoding"] == "base64" else patch["content"].encode("utf-8"))
                    self.assertTrue(decoded == original, f"PATCH byte mismatch: {name}/{relative}")
                    self.assertEqual(patch["executable"], executable)
            for name in set(entries) - selected:
                self.assertFalse((output / "skills" / name).exists())
            for name in ("security-audit", "fallow", "humanizer"):
                self.assertTrue((output / "skills" / name / "LICENSE").is_file())


if __name__ == "__main__":
    unittest.main()
