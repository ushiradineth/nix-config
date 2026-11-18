# Upstream and adaptation

- Repository: <https://github.com/caldoai/skills>
- Revision: `d5b68dace378219890d821adb3685538e2c69b04`
- Canonical source: `skills/prune-tests/SKILL.md`
- License: MIT, copyright 2026 Maze; accompanying `LICENSE` preserves upstream bytes.

The OpenCode adaptation keeps the behavior-first keep/rewrite/delete method. It limits work to the
requested suite, distinguishes boundary coverage from duplicate assertions, preserves active
absence/security contracts and requires consumer evidence before deleting test-only helpers. The
native slash command carries arguments instead of Claude-specific frontmatter.

To update, review the canonical skill and license at an exact revision, merge useful changes into
this adaptation and update the pin. Verify native discovery, command execution, formatting and flake
checks. Refresh the installed configuration through a separately authorized Home Manager apply.
