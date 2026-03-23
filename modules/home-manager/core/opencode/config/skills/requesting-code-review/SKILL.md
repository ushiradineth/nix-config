---
name: requesting-code-review
description:
  Use after substantial implementation and before merge to request structured review with explicit
  diff scope, severity levels, and readiness verdict.
---

# Requesting code review

## Trigger conditions

Use this skill when:

- a multi-file or high-risk change is complete
- a plan milestone is finished and needs review before continuing
- you are preparing to merge or open a PR

## Core rule

Review context must be explicit and scoped. Do not ask for a vague "quick check".

## Workflow

1. Define review range and intent.
   - Capture base and head references.
   - Summarize what changed and what requirements it should satisfy.
2. Dispatch reviewer.
   - Use a focused review request command.
   - Route review analysis through the `audit` subagent.
   - Provide exact files, diff range, and expected behavior.
3. Process findings by severity.
   - `Critical`: fix before any next step.
   - `Important`: fix before declaring completion.
   - `Minor`: optionally defer with rationale.
4. Re-verify after fixes.
   - Re-run relevant validation commands.

## Output contract

Return:

1. `Review scope`: base/head refs and changed files.
2. `Findings`: critical, important, minor.
3. `Actions`: fixes applied or explicit deferrals.
4. `Readiness`: ready, ready-with-concerns, or blocked.

## Anti-patterns

- requesting review without clear requirements or diff range
- ignoring critical or important findings without technical rationale
- treating review as optional for risky changes
