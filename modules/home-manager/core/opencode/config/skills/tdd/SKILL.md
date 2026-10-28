---
name: tdd
description:
  "Use a meaningful failing test to drive a behavior change when the existing native test seam is
  cheap and clear."
license: MIT
---

# Test driven change

Find the smallest observable behavior that should change. Use the component's language, framework
and public seam. Write the regression and run it against the old code. Confirm it fails because the
behavior is wrong, not because the fixture, import or environment is broken.

Make the smallest implementation that satisfies the behavior. Run the regression, then affected
checks. Refactor while the behavior stays pinned. Do not mock the function being tested, assert
private call order or create source-text tests that merely mirror the implementation.

If useful coverage would require a broad new harness or brittle mocks, use the closest executable
consumer check and explain the limitation. Do not force artificial tests for prose or trivial edits.
Report the observed failure and pass. Commit separation is optional and follows the user's delivery
scope; a failing test does not have to become a broken commit on a shared branch.
