---
description: Generate bounded variants, score them, and select one direction
agent: planner
---

Run beam-style option generation using args: `$ARGUMENTS`.

GPT-5.5 intent: create a small set of meaningfully different options, score them with evidence, then
converge.

Default workflow role:

- Planner applies this methodology implicitly when triage shows deep scope, high ambiguity, or real
  path tradeoffs.
- Use this command only as an optional manual override for explicit control or debugging.
- This command is planning-only and must not execute implementation changes.

Success criteria:

- Options are distinct and bounded.
- Scoring criteria are explicit.
- The selected option has a thin-slice next action and verification hint.
- Rejected options have concrete rejection reasons.

Output:

1. `Constraints`: required limits and exclusions.
2. `Variants`: 3 default, 7 maximum, each with a short summary.
3. `Score matrix`: correctness, risk, effort, reversibility, and evidence.
4. `Selection`: chosen variant and rationale.
5. `Next thin slice`: first implementation candidate and verification hint, planning only.

Stop rules:

- Stop if variants become near-duplicates.
- Stop and ask one focused question if constraints are too incomplete to score safely.
- Do not optimize for novelty over correctness or reversibility.
