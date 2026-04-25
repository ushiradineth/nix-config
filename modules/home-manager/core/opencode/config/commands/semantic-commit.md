---
description: Split changes into semantic commits with safe confirmations
agent: builder
---

Process semantic commits using args: `$ARGUMENTS`.

Supported flags:

- `--dry-run`: propose commit groups and messages only, do not commit.
- `--max-commits N`: cap the number of proposed commit groups.

GPT-5.5 intent: keep commit grouping outcome-first and evidence-backed, while using the configured
small model for lightweight title or subject generation where OpenCode routes it.

Success criteria:

- Groups are logical by feature, fix, refactor, docs, test, or chore.
- Commit subjects use Conventional Commit style and imperative mood.
- Secret-looking files are skipped and reported.
- No commit is created without explicit confirmation unless the user gave that exact instruction.

Workflow:

1. Inspect `git status --short`, `git diff`, and `git diff --cached`.
2. Group changes into logical units.
3. Draft Conventional Commit subjects for each group.
4. If `--dry-run` is present, stop after showing the plan.
5. Otherwise, present the plan and require explicit confirmation before creating commits.
6. Before each commit, run a verification gate for the current change group with fresh evidence.
7. When committing, stage only files for the current group and use `git commit -s -m "<subject>"`.
8. Never push automatically.

Stop rules:

- Stop if there are no changes to commit.
- Stop if grouping would mix unrelated changes.
- Stop if a file appears to contain secrets.
- If hooks fail, fix issues and create a new commit rather than amending.
