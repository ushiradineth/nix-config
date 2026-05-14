---
name: adversarial-self-play
description:
  Use when important outputs need break-first review. Run an inline attacker pass before readiness
  claims.
---

# Adversarial self play

## Trigger conditions

Use this skill when at least one is true:

- output affects architecture, security, reliability, or high-impact delivery decisions
- confidence appears high but empirical break attempts are missing
- a completion or readiness claim is about to be made

## Core rule

Separate builder and attacker roles. By default, run the attacker pass inline as a deliberate role
switch with no commitment to the current solution.

Do not invoke `task`, slash commands, or subagents from this skill. If a separate reviewer or agent
is needed, return a scoped handoff to the caller instead of launching it.

## Workflow

1. Define target artifact and expected behavior.
2. Run an inline attacker pass that attempts to break assumptions and edge cases.
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
