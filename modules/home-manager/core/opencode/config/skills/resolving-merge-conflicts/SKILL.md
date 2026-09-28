---
name: resolving-merge-conflicts
description:
  Use when a git merge or rebase is in progress and conflicted hunks must be resolved by source
  intent.
---

# Resolving merge conflicts

## Core rule

Resolve each hunk from the intent of both sides. Preserve both intents when compatible. When they
conflict, follow the stated goal of the merge or rebase and report the tradeoff without inventing
new behavior.

## Workflow

1. Apply `git-guardrails`, then inspect operation state, status, history, and the unmerged files.
2. Find the primary source for each side: commits, accepted plans, issues, PR discussion, tests, and
   nearby code that establish why each change exists.
3. Resolve one hunk at a time. State each side's intent, the selected resolution, and any behavior
   deliberately not preserved.
4. Verify that conflict markers and unmerged entries are gone, then run the repository's smallest
   relevant checks before broader checks.
5. Report the resolved files and remaining git operation. Treat staging, continuing, aborting, and
   committing as separate mutations that require explicit user intent.

## Safety rules

- Do not use broad `--ours` or `--theirs` resolution across files.
- Do not auto-stage, auto-continue, abort, commit, push, or rewrite history.
- Ask when incompatible source intents would change user-visible behavior.
- Preserve unrelated working-tree changes.

## Output

Return operation state, primary sources consulted, per-hunk intent decisions, validation evidence,
and the next git action requiring user approval.
