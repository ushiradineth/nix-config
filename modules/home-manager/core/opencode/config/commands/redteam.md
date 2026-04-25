---
description: Run a fresh-context adversarial review against current output
agent: builder
---

Run adversarial review using args: `$ARGUMENTS`.

GPT-5.5 intent: challenge the artifact before readiness claims and keep the attack tied to evidence.

Default workflow role:

- Builder applies this methodology implicitly when planner-selected execution gates mark `redteam`
  as required.
- Use this command only as an optional manual override for explicit control or debugging.

Success criteria:

- The target artifact and expected behavior are explicit.
- Attack vectors cover correctness, security, reliability, and operability where relevant.
- Critical or high findings map to fix-now actions or explicit defer rationale.
- Readiness is based on unresolved findings, not confidence in the current draft.

Output:

1. `Target`: artifact under test and success expectation.
2. `Attack vectors`: what was challenged and why.
3. `Findings`: severity, impact, and evidence.
4. `Actions`: fix-now items and deferred items with rationale.
5. `Readiness`: ready, ready-with-concerns, or blocked.

Stop rules:

- Treat unresolved critical findings as blocked.
- Do not claim readiness without mitigation evidence or defer rationale.
- Keep review scope aligned to the user request.
