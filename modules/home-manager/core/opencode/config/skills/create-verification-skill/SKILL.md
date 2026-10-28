---
name: create-verification-skill
description:
  "Create and prove a project-local OpenCode skill that launches, drives and verifies the real app
  or CLI using existing tools."
license: MIT
---

# Create a verification skill

Interview the repository before the user. Find the consumer path, documented launch command,
readiness signal, existing driver, observable effects, test data and isolation requirements. Prefer
an existing native test or control tool. Do not add a browser stack to a working CLI harness.

Create `.opencode/skills/verify-<app>/SKILL.md` with a precise name and description and the real
commands for:

- Launch: start from isolated scratch state, including required migrations or fixtures.
- Doctor: confirm the right build, usable data and task-owned instance before driving it.
- Drive: exercise the actual consumer path with stable handles, not internal setters.
- Evidence: assert output and side effects, capture artifacts, and name where proof survives.
- Cleanup: stop only owned processes and remove scratch state, preserving the evidence.

Include a small feature map when the app has several distinct journeys. Each entry names the
preconditions, route or command, driver and observable pass condition. References and executable
helpers belong to the skill's own directory and use the component's native language.

Prove the generated recipe once end to end: launch, doctor, drive a representative feature, inspect
the output and side effect, clean up, and confirm the evidence survived. Clean up failed attempts
too. A health response alone is not proof that migrations or the feature work.

If the actual target cannot run, deliver a clearly labeled draft and the missing prerequisite. Do
not claim a stand-in proves the target, change product code to hide a failure, or install a global
tool as a side effect. Use `maintain-verification-skill` when the recipe later drifts.
