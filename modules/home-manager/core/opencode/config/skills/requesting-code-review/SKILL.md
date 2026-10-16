---
name: requesting-code-review
description:
  Use after substantial implementation and before merge to review a fixed diff separately for
  repository standards and specification fidelity.
---

# Requesting code review

## Trigger conditions

Use this skill when:

- a substantive or risky change is complete; file count alone is not the trigger
- a substantive plan milestone needs review before continuing
- you are preparing to merge or open a PR

## Core rule

Pin the review to a fixed point and keep two axes separate:

- `Standards`: does the diff follow repository guidance and avoid unsupported quality regressions?
- `Spec`: does the diff implement the accepted request without omissions, wrong behavior, or scope
  creep?

One axis must not hide or rerank the other.

## Workflow

1. Pin the fixed point.
   - For a supplied commit/branch/tag/range, resolve it and record the exact commits and appropriate
     diff command (three-dot against a merge-base when reviewing branch changes).
   - For working-tree review, record HEAD, the scoped paths, staged and unstaged diffs, and relevant
     untracked file contents/hashes. Use `git diff --cached -- <paths>`, `git diff -- <paths>` and
     direct reads; do not stage or commit just to manufacture a fixed point.
   - Exclude unrelated dirty work. Recheck the scoped content before the verdict; re-pin/review any
     concurrent change instead of issuing a verdict on an obsolete snapshot.
   - Stop on a missing requested ref. If the requested scope has no changes, report that without
     treating an empty commit range as proof the working tree is empty.
2. Identify sources.
   - Spec source: accepted plan, user request, issue, or other originating artifact.
   - Standards sources: nearest `AGENTS.md`, contributing or coding guidance, and established local
     patterns. Skip rules already enforced by passing deterministic tooling.
3. Review both axes inline.
   - `Standards` findings cite the documented rule. Label uncodified smells as judgement calls.
   - `Spec` findings cite the originating requirement and identify missing, partial, incorrect, or
     unrequested behavior such as scope creep.
   - Include applicable adversarial/coherence questions in this pass rather than repeating an
     equivalent review ceremony. Do not invoke `task`, slash commands, or subagents from this skill.
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

1. `Review scope`: fixed point, HEAD and scoped paths; commit range or dirty-content identities and
   exact inspection commands as appropriate.
2. `Standards`: severity, location, cited rule or `judgement call`, and impact.
3. `Spec`: severity, location, cited requirement, and fidelity issue.
4. `Actions`: fixes applied or explicit deferrals.
5. `Readiness`: ready, ready-with-concerns, or blocked.

## Anti-patterns

- requesting review without clear requirements and an identifiable diff/snapshot
- merging Standards and Spec into one score or priority list
- treating a judgement call as a documented violation
- ignoring critical or important findings without technical rationale
- treating review as optional for risky changes
