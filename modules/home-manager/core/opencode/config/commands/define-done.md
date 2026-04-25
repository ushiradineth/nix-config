---
description: Define done criteria and evaluation rubric before generation
agent: planner
---

Define completion criteria using args: `$ARGUMENTS`.

GPT-5.5 intent: prevent wrong-hill optimization with a short outcome-first contract, not a long
process ritual.

Default workflow role:

- Planner applies this methodology implicitly during normal planner -> builder flow.
- Use this command only as an optional manual override for explicit control or debugging.
- This command is planning-only and must not execute implementation changes.

Success criteria:

- The target problem is stated in at most two sentences.
- Exactly two `Done means` bullets define completion.
- The rubric has 3-5 criteria with concrete pass bars.
- Non-goals and stop conditions are explicit.

Output:

1. `Problem`: two-sentence target statement.
2. `Done means`: exactly two bullets.
3. `Rubric`: criteria, pass bars, and scoring hints.
4. `Non-goals`: what must not be optimized.
5. `Escalation trigger`: when to stop and ask for clarification.

Stop rules:

- Stop if requirements conflict.
- Ask one focused question only when missing information changes the completion target.
- Do not draft implementation steps in this command.
