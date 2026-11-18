# Upstream and adaptation

- Repository: <https://github.com/caldoai/skills>
- Revision: `d5b68dace378219890d821adb3685538e2c69b04`
- Canonical source: `skills/untangle-codebase/SKILL.md`
- License: MIT, copyright 2026 Maze; accompanying `LICENSE` preserves upstream bytes.

The OpenCode adaptation retains the change-together question, hidden/needless links, surplus and
problem-to-fix mapping. It uses the existing refactoring workflow and native command instead of
Claude-specific invocation fields or a second goal/orchestration system.

Work ends at the requested structural outcome and verified behavior. The upstream whole-repository
loop becomes bounded review; special cases remain when external constraints require them. Existing
scope decides whether broad comment/test cleanup is included, without an unconditional preliminary
questionnaire. Explicit instructions to preserve tests remain authoritative.

To update, review the canonical skill and license at an exact revision, merge useful changes into
this adaptation and update the pin. Verify native discovery, command execution, formatting and flake
checks. Refresh the installed configuration through a separately authorized Home Manager apply.
