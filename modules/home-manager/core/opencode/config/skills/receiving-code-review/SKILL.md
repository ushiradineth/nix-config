---
name: receiving-code-review
description:
  Use when handling review feedback so responses are technical, verified, and implementation actions
  are sequenced safely.
---

# Receiving code review

## Core principle

Treat feedback as technical input to verify, not performative agreement to repeat.

## Workflow

1. Read fully before acting.
2. Clarify unclear items first.
   - If any review item is ambiguous, ask for clarification before implementing partial changes.
3. Verify against codebase reality.
   - Confirm each suggestion is correct for this repository and current constraints.
4. Prioritize and implement.
   - Fix blocking and correctness issues first, then quality and style items.
5. Validate each batch.
   - Re-run targeted checks after each meaningful batch of fixes.
6. Report concrete outcomes.
   - State what changed, what was deferred, and why.

## When to push back

Push back with technical evidence when a suggestion:

- breaks existing requirements or behavior
- depends on assumptions that do not hold in this repo
- introduces unnecessary scope beyond the request

## Output contract

Return:

1. `Clarifications`: questions that must be resolved first, or `none`.
2. `Accepted items`: fixes implemented.
3. `Rejected items`: technical reason for disagreement.
4. `Validation`: commands run and outcomes.

## Anti-patterns

- blind implementation of all feedback without verification
- partial execution when unresolved review items may affect approach
- vague replies without technical rationale
