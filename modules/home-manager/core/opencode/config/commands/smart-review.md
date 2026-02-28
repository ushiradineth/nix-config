---
description: Analyze context and produce a focused review game plan
agent: plan
---

Run a smart review for target: `$ARGUMENTS`.

If no target is provided, analyze the current repository root.

Scope discovery checklist:

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
- Do not assume MCP tools.
- Use only available tools in this runtime.
- Keep output actionable and compact.
