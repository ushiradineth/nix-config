---
description: Analyze context and produce a focused review game plan
agent: planner
---

Run a smart review for target: `$ARGUMENTS`.

If no target is provided, analyze the current repository root.

Scope discovery checklist:

- Start with retrieval calls (`veil_discover`, `veil_files`, `veil_symbols`, `veil_search`) to
  locate relevant source and config files.
- Rely on Veil server auto-init and query auto-refresh defaults.
- Call `veil_status` or `veil_refresh` only when explicitly requested, troubleshooting stale
  behavior, or after very large refactor/index events.
- If Veil retrieval is insufficient, read likely target files directly instead of switching tools.
- Run scope drift detection: compare requested intent against changed files and recommend narrowing
  review to requested scope first, then out-of-scope deltas.
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
4. `Fix-first classification`: split findings into `AUTO-FIX` (mechanical) and `ASK` (judgment).
5. `Suggested actions`: concrete next actions with expected outcome.
6. `Escalation triggers`: what findings should trigger deeper review or broader checks.

If the target is a file, include file-specific checks.

If the target is a directory or project, include:

- one quick pass plan
- one deep pass plan
- a stop condition for each pass

Rules:

- Do not switch to external role systems.
- Use veil MCP tools as the primary discovery path.
- Keep output actionable and compact.
