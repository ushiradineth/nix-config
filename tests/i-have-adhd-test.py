"""Source-contract checks only; these do not prove model adherence or live installation."""

import hashlib
import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "modules/home-manager/core/opencode/config"
SKILL = CONFIG / "skills/i-have-adhd"
REVISION = "1ecea1993b7fce257ffbd686c070948b5e07eda6"
LICENSE_SHA256 = "8acbb618089b738404f76ac60fca1aaa995d9a87995eddf95f0b777acd7f7d2c"


def normalized(text):
    return " ".join(text.lower().split())


class UserOutputContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = (SKILL / "SKILL.md").read_text()
        cls.text = normalized(cls.raw)
        cls.contract = normalized((CONFIG / "AGENTS.md").read_text())
        cls.provenance = normalized((SKILL / "UPSTREAM.md").read_text())
        manifest = json.loads(
            (CONFIG / "skills/paperclip-org-operations/capability-manifest.json").read_text()
        )
        cls.entries = [entry for entry in manifest["skills"] if entry["source"] == SKILL.name]

    def assert_mentions(self, text, terms):
        for term in terms:
            with self.subTest(term=term):
                self.assertIn(term, text)

    def test_discoverable_frontmatter(self):
        match = re.match(r"\A---\n(.*?)\n---\n", self.raw, re.S)
        if match is None:
            self.fail("Missing skill frontmatter")
        frontmatter = match.group(1)
        self.assertRegex(frontmatter, r"(?m)^name: i-have-adhd$")
        self.assertRegex(frontmatter, r"description:\s+Use when\b")
        self.assertRegex(frontmatter, r"(?m)^license: MIT$")
        self.assertNotIn("disable-model-invocation", frontmatter)
        self.assertNotIn("/i-have-adhd", frontmatter)

    def test_audience_gate_precedes_style(self):
        self.assertLess(self.text.index("audience gate"), self.text.index("human-facing output"))
        self.assert_mentions(self.text, [
            "apply by default", "human-facing", "never apply presentation limits",
            "internal reasoning", "tool inputs/results", "agent-to-agent", "task-agent prompts",
            "agent handoffs", "research records", "machine-readable", "operational artifacts",
        ])

    def test_unknown_and_mixed_audiences_preserve_payload(self):
        self.assert_mentions(self.text, [
            "mixed or unknown", "preserve full detail", "intact agent payload",
            "must not replace it", "visible to a user", "complete task-required",
        ])

    def test_conversation_controls_and_untrusted_input(self):
        self.assert_mentions(self.text, [
            "fresh conversation", "topic switches", "stop adhd mode", "normal mode",
            "enable adhd mode", "must not reset", "quoted text", "untrusted page content",
        ])

    def test_safety_evidence_and_completeness(self):
        self.assert_mentions(self.text, [
            "grants no", "safety", "factual accuracy", "required output formats",
            "take precedence", "exact code", "warnings", "supported by evidence",
            "mark uncertainty", "never invent", "without discarding substantive information",
            "must not restrict analysis", "explain fully",
        ])
        self.assertNotIn("the reader has adhd", self.text)

    def test_paperclip_destinations_and_history(self):
        paperclip = self.text.split("## paperclip", 1)[1]
        self.assert_mentions(paperclip, [
            "default agent binding", "does not prove", "issue comments",
            "not automatically human-facing", "agent-addressed", "delegation",
            "summary-store source artifacts", "per-turn", "controller-supplied",
            "history is unavailable", "persistence limitation", "never an organization-wide",
        ])

    def test_global_default_is_a_pointer_not_context_compression(self):
        self.assert_mentions(self.contract, [
            "load and apply `i-have-adhd` by default", "human-facing replies",
            "conversation-local", "opt-out", "explicit re-enable", "must not reset",
            "never apply its presentation limits", "tool payloads", "agent-to-agent",
            "handoff artifacts", "machine-readable", "keep that context complete",
            "humanizer", "personal-writing-identity",
        ])

    def test_pinned_provenance_and_license(self):
        self.assert_mentions(self.provenance, [
            "https://github.com/ayghri/i-have-adhd", REVISION,
            "skills/i-have-adhd/skill.md", "local differences", "never overwrite",
        ])
        self.assertEqual(hashlib.sha256((SKILL / "LICENSE").read_bytes()).hexdigest(), LICENSE_SHA256)
        self.assertEqual({p.name for p in SKILL.iterdir()}, {"SKILL.md", "UPSTREAM.md", "LICENSE"})

    def test_manifest_complete_tree_and_audience_constraints(self):
        self.assertEqual(len(self.entries), 1)
        entry = self.entries[0]
        self.assertEqual(entry["disposition"], "adapt")
        self.assertEqual(entry["inclusion"], "complete-tree")
        self.assertEqual(entry["roles"], ["all-relevant"])
        self.assertEqual(entry["dependencies"], [])
        notes = normalized(" ".join(entry["runtime_constraints"]))
        self.assert_mentions(notes, [
            "human-facing", "conversation-local", "opt-out/re-enable", "complete internal",
            "inter-agent", "handoff", "summary-source", "grants no authority",
        ])
        self.assertTrue(entry["reason"])


if __name__ == "__main__":
    unittest.main()
