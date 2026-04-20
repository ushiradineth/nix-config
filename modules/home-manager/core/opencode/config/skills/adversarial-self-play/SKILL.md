---
name: adversarial-self-play
description:
  Use when important outputs need break-first review. Run a fresh-context attacker pass before
  readiness claims.
---

# Adversarial self play

## Trigger conditions

Use this skill when at least one is true:

- output affects architecture, security, reliability, or high-impact delivery decisions
- confidence appears high but empirical break attempts are missing
- a completion or readiness claim is about to be made

## Core rule

Separate builder and attacker roles. The attacker must run in fresh context with no commitment to
the current solution.

## Workflow

1. Define target artifact and expected behavior.
2. Run attacker pass that attempts to break assumptions and edge cases.
3. Classify findings by severity and confidence.
4. Feed findings into fix plan with smallest safe mitigation first.
5. Re-verify mitigations and update readiness status.

## Output contract

Return:

1. `Target`: artifact and expected behavior.
2. `Attack plan`: what will be challenged.
3. `Findings`: severity, confidence, evidence.
4. `Mitigations`: fix-now vs defer with rationale.
5. `Readiness impact`: ready, ready-with-concerns, or blocked.

## Anti-patterns

- attacker reusing builder assumptions without challenge
- readiness claims made before adversarial findings are resolved
- collapsing all findings into one generic risk statement
