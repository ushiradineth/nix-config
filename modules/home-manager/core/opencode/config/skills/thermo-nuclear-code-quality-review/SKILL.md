---
name: thermo-nuclear-code-quality-review
description:
  "Run an explicit deep maintainability review for structural simplification, needless layers,
  tangled state, boundary leaks and type-contract problems."
license: MIT
---

# Thermo-nuclear code quality review

Review the scoped branch or diff with an ambitious simplification standard. Stay read-only unless
the user asked to apply improvements. Correct behavior alone does not excuse a structural
regression.

Look for a reorganization that deletes concepts: a better owner, domain model or direct flow that
removes whole branches, wrappers and hidden state. Distinguish simplification from moving the same
complexity into more files.

Prioritize:

1. Structural regressions and a concrete simpler design that preserves behavior.
2. Scattered feature checks, boolean modes and repeated special cases indicating a missing model.
3. Leaked ownership, duplicate canonical helpers and pass-through abstractions.
4. Casts, unnecessary optionality and boundary ambiguity that obscure invariants.
5. Related writes that can leave partial state, and needless orchestration that complicates
   reasoning.
6. File growth that destroys cohesion. Crossing roughly 1,000 lines is a prompt to inspect
   structure, not proof that an arbitrary extraction helps.

For each finding, cite the source, explain the reader or maintainer cost, and propose the smallest
structural remedy with a way to preserve behavior. Prefer a few high-confidence findings over a
catalog of preferences. Do not invent future requirements or demand abstractions for their own sake.

Report serious findings first, then the strongest simplification opportunity, and validation limits.
A clean result is valid. An explicit implementation request may follow accepted improvements with
behavioral checks; a review request alone does not authorize a rewrite.
