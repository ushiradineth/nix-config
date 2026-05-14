---
name: test-driven-development
description:
  Use when implementing a feature or bug fix where behavior can be verified through tests,
  especially when the user mentions TDD, regression tests, red-green-refactor, or integration tests.
---

# Test driven development

## Core rule

One behavior at a time. Red, green, then refactor. Never refactor while red.

## Workflow

1. Identify the public interface or user-visible behavior.
2. Write one failing test for one behavior.
3. Run it and confirm it fails for the expected reason.
4. Write the smallest implementation that passes.
5. Run the test and relevant nearby checks.
6. Refactor only after green, then run checks again.
7. Repeat for the next behavior.

## Test quality

- Prefer behavior tests through public interfaces.
- Avoid tests coupled to private implementation details.
- Each test should survive internal refactors when behavior stays the same.
- Do not write a batch of imagined tests before the first implementation slice teaches you more.

## When not to use

- Pure formatting or prompt-only changes.
- Config changes with no meaningful test seam, where parse or build checks are the right evidence.
