---
name: test-driven-development
description:
  Use when implementing a feature or bug fix where behavior can be verified through tests,
  especially when the user mentions TDD, regression tests, red-green-refactor, or integration tests.
---

# Test driven development

## Core rule

One behavior at a time. Red, green, then refactor. Never refactor while red.

Test at a seam, the public interface where behavior is observable without reaching into the
implementation. Use a seam already established by the accepted plan or codebase. Ask only when the
choice is materially ambiguous.

## Workflow

1. Identify one user-visible behavior and the seam that exposes it.
2. Confirm the seam from the accepted plan, existing interface, or user answer. Do not add a seam
   only to make testing convenient.
3. Write one failing test for one behavior.
4. Run it and confirm it fails for the expected reason.
5. Write the smallest implementation that passes.
6. Run the test and relevant nearby checks.
7. Refactor only after green, then run checks again.
8. Repeat for the next vertical slice.

## Test quality

- Prefer behavior tests through public interfaces.
- Avoid implementation-coupled tests that mock private collaborators or assert internal calls.
- Each test should survive internal refactors when behavior stays the same.
- Avoid tautological assertions that calculate the expected result using the implementation's own
  logic. Use an independent literal, worked example, or specification.
- Avoid horizontal slicing. Do not write a batch of imagined tests before the first implementation
  slice teaches you more.

## When not to use

- Pure formatting or prompt-only changes.
- Config changes with no meaningful test seam, where parse or build checks are the right evidence.
