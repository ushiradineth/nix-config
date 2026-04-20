---
description: Run a fresh-context adversarial review against current output
agent: builder
---

Run adversarial review using args: `$ARGUMENTS`.

Use this command to challenge proposals, plans, or implementation outputs before claiming readiness.

Default workflow role:

- Builder should apply this methodology implicitly when planner-selected execution gates mark
  redteam as required.
- Use this command as an optional manual override for explicit control or debugging.

Workflow:

1. Restate target artifact and expected behavior.
2. Run a fresh-context attack pass with no commitment to current solution.
3. Generate break attempts across correctness, security, reliability, and operability.
4. Classify findings by severity: `critical`, `high`, `medium`, `low`.
5. Map each `critical` or `high` finding to a concrete fix or explicit defer rationale.
6. Re-evaluate readiness based on unresolved findings.

Output contract:

Return all sections:

1. `Target`: artifact under test and success expectation.
2. `Attack vectors`: what was challenged and why.
3. `Findings`: severity, impact, and evidence.
4. `Actions`: fix-now items and deferred items with rationale.
5. `Readiness`: ready, ready-with-concerns, or blocked.

Safety gates:

- Treat unresolved `critical` findings as blocked.
- Do not claim readiness without evidence for mitigation or defer rationale.
- Keep review scope aligned to user request.
