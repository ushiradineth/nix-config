---
name: fix-merge-conflicts
description:
  "Resolve an existing conflicted merge or rebase from both sides' intent and verify the result
  without unrelated refactoring."
license: MIT
---

# Fix merge conflicts

Inspect the actual operation, base, both sides and `git status`. Preserve unrelated dirty work. If
no operation is conflicted, report that; do not start a merge just to create work.

Resolve each file according to the intended behavior of both changes. A compiling side is not
automatically the correct side. Inspect callers and tests when both sides changed the contract.
Regenerate generated files and lockfiles with their authoritative tools; do not invent lock entries.

Check for unresolved index entries and conflict markers in the affected files. Run the native build,
lint and behavioral checks required for the merged result. Keep the patch focused.

Stage only resolved task files. Continue the existing merge/rebase when completing that operation is
part of the request and verification passed. If hooks or a required check fails, fix the cause or
report it. Do not bypass hooks, abort unrelated work, push, tag or rewrite shared history as a side
effect. Report the resolution choices, verification and operation state.
