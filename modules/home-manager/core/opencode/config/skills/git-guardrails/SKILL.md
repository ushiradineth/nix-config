---
name: git-guardrails
description:
  Use before git mutation, branch deletion, resets, cleaning, force pushes, broad restore commands,
  PR operations, or any git action with destructive or remote side effects.
---

# Git guardrails

## Core rule

Use prompt and permission safety. Do not add hook scripts unless the user explicitly asks.

## Always inspect first

- `git status --short`
- `git diff`
- `git diff --cached`
- `git log --oneline -n 15` when history matters

## Ask first

- `git push`
- `git reset --hard`
- `git clean -f` or stronger
- `git branch -D`
- `git checkout .` or broad `git restore .`
- force push, amend, rebase, or history rewrite
- committing files that may contain secrets

## Commit rule

Commit only when the user explicitly asks. If committing, use repository style and do not bypass
hooks.

## Merge and rebase conflicts

Apply `resolving-merge-conflicts` when an operation has unmerged entries. Resolve from both sides'
primary sources and inspect each hunk. Staging, continuing, aborting, and committing remain separate
git mutations that require explicit user intent.

## Output

State the intended git action, the evidence inspected, and the safety decision: proceed, ask, or
block.
