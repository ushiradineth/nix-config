---
name: engineering-quality
description:
  Use when planning, implementing, diagnosing, or reviewing software in OpenCode or Paperclip, or
  coordinating a task that needs explicit completion evidence. Routes the shared quality gates
  without changing agent authority.
---

# Engineering quality

Use the same completion standard across runtimes. A skill teaches a procedure; it does not grant
repository, shell, browser, service, or deployment access.

## Start with the outcome

1. State the target problem in at most two sentences and identify the accepted request.
2. Define two `Done means` bullets, concrete pass bars, non-goals, and escalation conditions before
   substantial implementation. For a small task, keep this proportional to the work.
3. Inspect available context before asking questions. Ask one focused question only when the answer
   changes scope, safety, architecture, or acceptance.
4. Verify planned targets against the working tree. Preserve unrelated changes and state material
   assumptions before editing.

## Route by task

- Coding, design, diagnosis, or review: read `references/coding.md` and load only the applicable
  named techniques from the actual skill inventory.
- Paperclip execution, task handoffs, or generated skill names: read `references/paperclip.md`.
- Writing/research without code: preserve facts and sources; use relevant domain/writing skills and
  authorized tool evidence. Do not run coding commands merely to follow this skill.
- Browser testing: use `browser-workflow` only within the approved target and agent authority.

## Close with evidence

Pair each claimed outcome with a fresh command, authorized tool result, or source artifact.
Distinguish verified, failed, and untested work. A catalog entry, plausible explanation, or
successful connection test is not proof of behavior. Stop at the accepted done criteria.

Do not create agents, change models or permissions, run consequential actions, or start recurring
work to compensate for a missing capability. Return the exact blocker and smallest next action.
