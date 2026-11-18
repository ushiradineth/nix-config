---
name: untangle-codebase
description:
  Use when asked to untangle a codebase or subsystem, reduce hidden coupling, or reorganize modules
  around responsibilities that change together.
---

# Untangle a codebase

Ask of the design: **should these pieces change together?** Bring related rules under one owner and
separate responsibilities that change for different reasons.

Use the user's requested area and outcome as the boundary. A review produces findings; an
implementation request authorizes the scoped refactor. Follow the existing
[refactoring playbook](../jiyu-mode/playbooks/refactoring.md) for baseline checks and integration.
Ordinary bug fixes do not authorize a codebase-wide rewrite.

## Map before changing

Trace real callers, imports, state and externally visible contracts. Use change history when it
helps establish what changes together. Record concrete problems, their affected paths and the
behavior that must survive:

- **Hidden links:** duplicated rules, implicit call order, shared globals or related feature logic
  scattered across layers.
- **Needless links:** callers depending on private details, stable domain code depending directly on
  volatile integrations, or shared APIs carrying one caller's special vocabulary.
- **Surplus:** unused code, pass-through wrappers or extension points without a present requirement.

Treat retries, exceptions, special cases and disabled tests as evidence to investigate. They may
encode real external constraints; their count alone is not a design-quality measure.

## Choose the owner, then refactor

Group related problems under a fix that removes concepts rather than relocating complexity. Name the
owner, contract and migration needed before editing. Avoid a new abstraction unless it removes
demonstrated coupling.

For example, checkout importing Stripe directly may hide the payment operation it actually needs.
Move provider-specific handling behind an existing payment boundary, or introduce the smallest
boundary justified by current callers. Preserve required rate-limit retries. An unrelated refunds
bug does not become part of a checkout-only refactor.

Migrate affected callers in coherent steps, verify the behavioral baseline and remove obsolete
paths. Include directly affected comments and tests in the migration. Broad comment cleanup or test
pruning is separate work unless requested; use `prune-tests` when that work is in scope. Honor an
explicit request to leave tests unchanged rather than silently rewriting them.

## Finish within the boundary

Review the scoped result for remaining hidden links, needless links and surplus. Use bounded
independent review when it adds useful coverage and delegation is available. Repeat only for a
material change or an unresolved in-scope finding.

Finish when the requested coupling is resolved, callers use the new owner, intended behavior is
preserved and the affected checks pass. Report unrelated findings separately, along with any blocked
checks or remaining constraints. Do not keep refactoring until the whole repository has nothing left
to improve.
