---
description: Analyze context and produce a focused review game plan
agent: planner
---

Run a smart review for target: `$ARGUMENTS`.

If no target is provided, analyze the current repository root.

Scope discovery checklist:

- Call `veil_status` before broad discovery.
- If index is missing or stale, call `veil_refresh` with `mode: changed`.
- Use `veil_files`, `veil_symbols`, and `veil_search` to locate relevant source and config files.
- Only fall back to broad `glob` or `grep` when index results are insufficient.
- Identify stack and subsystem from nearby config and source files.
- Classify change risk: low, medium, high.
- Detect high-signal areas: auth, permissions, input parsing, migrations, network boundaries, build
  and deploy paths.
- Detect quality hotspots: flaky tests, complex branching, duplicated logic, missing docs, stale
  patterns.

Return this report format:

1. `Detected context`: file types, subsystem, and likely risk areas.
2. `Priority lenses`: rate each lens `0-3` with one-line reason.
   - security
   - correctness
   - performance
   - maintainability
   - UX
   - testing
3. `Review strategy`: ordered checklist with fastest high-value checks first.
4. `Suggested actions`: concrete next actions with expected outcome.
5. `Escalation triggers`: what findings should trigger deeper review or broader checks.

If the target is a file, include file-specific checks.

If the target is a directory or project, include:

- one quick pass plan
- one deep pass plan
- a stop condition for each pass

Rules:

- Do not switch to external role systems.
- Use veil MCP tools as the primary discovery path.
- Keep output actionable and compact.
