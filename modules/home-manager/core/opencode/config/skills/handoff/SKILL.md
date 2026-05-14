---
name: handoff
description:
  Use when work should continue in another session, another lane, or a fresh context window,
  especially after planning, debugging, or partial implementation.
---

# Handoff

## Core rule

Write only what the next session needs. Reference existing artifacts instead of duplicating them.

## Workflow

1. Identify the next lane: `builder`, `direct`, `sudo`, or `init`.
2. Reference source artifacts: plan path, branch, commit, issue, PR, logs, or validation output.
3. Capture current status, blockers, assumptions, and exact next action.
4. Suggest relevant skills for the next session.

## Output shape

```md
Handoff target: builder | direct | sudo | init Source artifact: <path or URL> Current state:
<short status> Next action: <one command or task> Relevant skills: <skill names or none>
```

## Rules

- Do not duplicate full plans, diffs, or logs when a path is enough.
- Prefer `.agents/plans/*` for durable implementation handoffs.
- Use temp files only for throwaway handoffs that should not become state.
