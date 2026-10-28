---
name: swarm
description:
  "Fan out independent coverage slices or declared races and aggregate one evidence-based result.
  Use for swarm or explicitly parallel coverage."
license: MIT
---

# Swarm

State the done check and choose coverage slices or a race. For races, declare first-pass, rank-all
or best-of before launching. For coverage, list every required slice so a missing result stays
visible.

Use the runtime's bounded worker tool and configured concurrency. Workers inherit the active model
unless configured otherwise. Give each a self-contained goal, scope, output, check and stop
condition. Name exact commits and measurement method when comparisons require them. No nested
delegation.

Give writers disjoint files or separate worktrees. Read-only workers may share source; test or build
output that mutates a shared directory still needs isolation. Do not create cloud resources or locks
to imitate unsupported Cursor fields.

Collect terminal results. Each slice returns PASS, ISSUES or BLOCKED with evidence. Missing or
invalid results are gaps, never passes. Retry a missing result once when useful, then report the
gap. For a race, apply the declared rule; for coverage, every required slice needs a result.

Inspect the artifacts and return one compact result table with confirmed issues, gaps and evidence.
Use `arena` instead when the task is choosing and combining competing designs.
