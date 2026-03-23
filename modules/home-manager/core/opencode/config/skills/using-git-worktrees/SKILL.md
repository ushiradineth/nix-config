---
name: using-git-worktrees
description:
  Use when setting up isolated implementation streams for risky or parallel work. Create predictable
  worktree locations and verify clean baselines.
---

# Using git worktrees

## Trigger conditions

Use this skill when:

- starting non-trivial feature work that should not pollute the current tree
- running parallel streams that may conflict
- preparing heavy validation runs and wanting isolation

## Directory selection priority

1. use `.worktrees/` if it exists
2. else use `worktrees/` if it exists
3. else ask user for preferred location

If project-local worktree directories are used, ensure they are gitignored before creating
worktrees.

## Workflow

1. Choose worktree path with the priority above.
2. Create branch and worktree.
3. Run project setup steps required by repository tooling.
4. Run baseline validation to confirm clean starting state.
5. Report full path and baseline results.

## Safety gates

- do not proceed with baseline failures without explicit user direction
- do not mutate unrelated files in the primary tree while preparing the worktree
- keep `.agents/MEMORIES.md` and `.agents/PROGRESS.md` updates in the main repo when working from a
  worktree

## Output contract

Return:

1. `Path`: full worktree path.
2. `Branch`: created or reused branch name.
3. `Baseline`: verification commands and outcomes.
4. `Ready`: yes or blocked with reason.
