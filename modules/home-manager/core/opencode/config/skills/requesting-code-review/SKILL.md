---
name: requesting-code-review
description:
  Use after substantial implementation and before merge to review a fixed diff separately for
  repository standards and specification fidelity.
---

# Requesting code review

## Trigger conditions

Use this skill when:

- a multi-file or high-risk change is complete
- a plan milestone is finished and needs review before continuing
- you are preparing to merge or open a PR

## Core rule

Pin the review to a fixed point and keep two axes separate:

- `Standards`: does the diff follow repository guidance and avoid unsupported quality regressions?
- `Spec`: does the diff implement the accepted request without omissions, wrong behavior, or scope
  creep?

One axis must not hide or rerank the other.

## Workflow

1. Pin the fixed point.
   - Resolve the supplied commit, branch, tag, or merge-base before reviewing.
   - Record the exact three-dot diff command, commit range, and changed files.
   - Stop on a missing ref or empty diff.
2. Identify sources.
   - Spec source: accepted plan, user request, issue, or other originating artifact.
   - Standards sources: nearest `AGENTS.md`, contributing or coding guidance, and established local
     patterns. Skip rules already enforced by passing deterministic tooling.
3. Review both axes inline.
   - `Standards` findings cite the documented rule. Label uncodified smells as judgement calls.
   - `Spec` findings cite the originating requirement and identify missing, partial, incorrect, or
     unrequested behavior such as scope creep.
   - Do not invoke `task`, slash commands, or subagents from this skill.
   - Primary agents may route analysis through `audit` only when the user or accepted plan
     explicitly requests one first-level leaf review.
   - A subagent returns a scoped review handoff because it is a leaf executor.
4. Process findings by severity within each axis.
   - `Critical`: fix before any next step.
   - `Important`: fix before declaring completion.
   - `Minor`: optionally defer with rationale.
5. Re-verify after fixes.
   - Re-run relevant validation commands.

## Output contract

Return:

1. `Review scope`: fixed point, head, diff command, commits, and changed files.
2. `Standards`: severity, location, cited rule or `judgement call`, and impact.
3. `Spec`: severity, location, cited requirement, and fidelity issue.
4. `Actions`: fixes applied or explicit deferrals.
5. `Readiness`: ready, ready-with-concerns, or blocked.

## Anti-patterns

- requesting review without clear requirements or diff range
- merging Standards and Spec into one score or priority list
- treating a judgement call as a documented violation
- ignoring critical or important findings without technical rationale
- treating review as optional for risky changes
