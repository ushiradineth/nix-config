---
name: deslop
description: Remove AI-generated code slop and clean up code style
---

# Remove AI code slop

Use the caller's scoped files or diff, including task-owned untracked files. Remove AI-generated
slop only within that scope. When no scope is supplied, inspect the branch and working tree to
choose the relevant base and state what is being reviewed; do not assume a branch named main.

## Focus Areas

- Extra comments that are unnecessary or inconsistent with local style
- Defensive checks or try/catch blocks that are abnormal for trusted code paths
- Casts to `any` used only to bypass type issues
- Deeply nested code that should be simplified with early returns
- Other patterns inconsistent with the file and surrounding codebase

## Guardrails

- Keep behavior unchanged unless fixing a clear bug.
- Prefer minimal, focused edits over broad rewrites.
- Keep the final summary concise (1-3 sentences).
