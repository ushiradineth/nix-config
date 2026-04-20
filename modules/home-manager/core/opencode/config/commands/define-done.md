---
description: Define done criteria and evaluation rubric before generation
agent: planner
---

Define completion criteria using args: `$ARGUMENTS`.

Use this command before generation-heavy work to prevent wrong-hill optimization.

Default workflow role:

- Planner should apply this methodology implicitly during normal planner -> builder flow.
- Use this command as an optional manual override for explicit control or debugging.

Planning boundary:

- This command is planning-only and must not execute implementation changes.

Workflow:

1. Restate the target problem in at most two sentences.
2. Write exactly two `Done means` lines.
3. Produce an evaluation rubric with 3-5 criteria.
4. Add pass bars for each criterion.
5. List explicit non-goals.
6. Add one stop condition that triggers escalation when target-fit evidence is weak.

Output contract:

Return all sections:

1. `Problem`: two-sentence target statement.
2. `Done means`: exactly two bullets.
3. `Rubric`: criteria, pass bars, and scoring hints.
4. `Non-goals`: what must not be optimized.
5. `Escalation trigger`: when to stop and ask for clarification.

Safety gates:

- Keep scope tied to user request.
- Do not draft implementation steps in this command.
- If requirements conflict, stop and escalate with one focused clarification question.
- Do not choose defaults for conflicting requirements.
