---
description: Generate bounded variants, score them, and select one direction
agent: planner
---

Run beam-style option generation using args: `$ARGUMENTS`.

Use this command when one linear draft is likely to miss better alternatives.

Default workflow role:

- Planner should apply beam-style methodology implicitly when triage signals deep scope or high
  ambiguity.
- Use this command as an optional manual override for explicit control or debugging.

Planning boundary:

- This command is planning-only and must not execute implementation changes.

Workflow:

1. Parse constraints from user request and active plan.
2. Generate `N` distinct variants (default `N=3`, max `N=7`).
3. Score each variant on correctness, risk, effort, and reversibility.
4. Select the strongest variant and explain why.
5. List weak spots that still need improvement.
6. Propose a thin-slice next action for the selected variant.

Output contract:

Return all sections:

1. `Constraints`: required limits and exclusions.
2. `Variants`: short summary for each candidate.
3. `Score matrix`: per-criterion scores and brief evidence.
4. `Selection`: chosen variant and rationale.
5. `Next thin slice`: first implementation candidate and verification hint, planning only.

Safety gates:

- Keep `N` bounded to prevent unproductive variant sprawl.
- Reject near-duplicate variants.
- If constraints are missing, ask one focused question or use a safe default and state it.
