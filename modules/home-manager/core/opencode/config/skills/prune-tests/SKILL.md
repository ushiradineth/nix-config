---
name: prune-tests
description:
  Use when asked to prune redundant or implementation-coupled tests, or simplify a test suite while
  preserving its behavioral coverage.
---

# Prune tests

Work within the requested suite or path. A review request stays read-only; a pruning request
authorizes focused test changes. Ordinary feature work does not trigger a suite-wide cleanup.

For each candidate, identify the intended behavior and a plausible regression that would make it
fail. Classify it as keep, rewrite or delete, with evidence:

- Keep tests of independent behavior, boundary wiring, error cases and security or compatibility
  contracts. Similar assertions at unit and integration levels can guard different failures.
- Rewrite tests coupled to private state, helper calls or copied implementation logic when they also
  protect a real contract. Use independently specified inputs and expected outcomes.
- Delete tautologies, tests that mock the unit under test and assert the mock's return, and true
  duplicates whose inputs, boundary and failure modes are already covered.
- An absence assertion may enforce an active prohibition, such as preventing an insecure route from
  returning. Remove it only when it protects no current requirement.

Do not infer redundancy from coverage percentages or matching test names alone. Trace callers and
requirements when the contract is unclear; keep uncertain coverage rather than guessing.

For example, replace an expected discount calculated with the production formula with a specified
case: a price of 100 with a 20% discount must produce 80. Keep a separate HTTP test if it also
checks that the discount reaches checkout through the real request boundary.

Capture the existing test baseline, make the scoped changes, then run the affected suite and
required repository checks. Remove a test-only production helper only after checking references,
exports and consumers and establishing that no runtime contract needs it. Never remove code or a
test merely to make a failing check disappear.

Finish with the tests kept, rewritten or removed, the behavior still covered and check results.
