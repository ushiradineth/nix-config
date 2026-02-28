---
description: Split changes into semantic commits with safe confirmations
agent: build
---

Process semantic commits using args: `$ARGUMENTS`.

Supported flags:

- `--dry-run`: propose commit groups and messages only, do not commit.
- `--max-commits N`: cap the number of proposed commit groups.

Workflow:

1. Inspect `git status --short`, `git diff`, and `git diff --cached`.
2. Group changes into logical units by feature, fix, refactor, docs, test, or chore.
3. Draft Conventional Commit subjects for each group.
4. If `--dry-run` is present, stop after showing the plan.
5. Otherwise, present the plan and require explicit confirmation before creating commits.
6. When committing, stage only files for the current group and use `git commit -s -m "<subject>"`.
7. Never push automatically.

Safety rules:

- Never use destructive git operations.
- Skip files that appear to contain secrets and warn the user.
- If a commit fails due to hooks, fix issues and create a new commit.
