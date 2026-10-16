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

1. Identify the next owner: an OpenCode lane (`builder`, `direct`, `planner`, or `sudo`), or an
   authorized Paperclip issue assignee. Do not invoke OpenCode primary agents from Paperclip.
2. Reference source artifacts: plan path, branch, commit, issue, PR, logs, or validation output.
3. Capture current status, blockers, assumptions, and exact next action.
4. Suggest relevant skills for the next session.

## Output shape

```md
Handoff target: builder | direct | planner | sudo Source artifact: <path or URL> Current state:
<short status> Next action: <one command or task> Relevant skills: <skill names or none>
```

## Rules

- Do not duplicate full plans, diffs, or logs when a path is enough.
- Prefer `.agents/plans/*` for durable implementation handoffs.
- For OpenCode repository-guidance work, name builder as owner and `/init` as the next action;
  `/init` is a command, not an agent. Use direct for clear bounded coding without a plan handoff.
- In Paperclip, use the approved issue/plan artifact and a bounded child issue or durable checkpoint
  instead of requiring `.agents` files or a fresh OpenCode session. Include workspace, branch,
  commit, validation evidence, and the named next owner; preserve existing delegation authority.
- Use temp files only for throwaway handoffs that should not become state.
