---
name: jiyu-mode
description:
  "Route coding, investigation, design, verification and PR work through a task-sized seojiyu
  playbook. The default for substantive work."
license: MIT
---

# Jiyu mode

Own the goal and the proof. Pick the shortest playbook that can deliver both. Keep routine work in
this session; add design exploration, independent review or parallel workers where they improve the
result. This is Seojiyu, the OpenCode adaptation of pstack.

## Start and route

State the intended outcome briefly, then ground it in the repository. If the request is ambiguous,
use `in-your-own-words`; do not wait for approval of an obvious restatement. Identify a checkable
finish condition before changing behavior. A simple edit needs neither a todo list nor a plan.

For multi-step work, keep a short live checklist of the selected playbook's applicable steps.
Explain a material omission when it affects confidence. Do not copy irrelevant steps just to skip
them. Read only the matching file:

| Task                                                            | Playbook                                           |
| --------------------------------------------------------------- | -------------------------------------------------- |
| Personal budgets, Gmail, tax records or AFFiNE notes/reviews    | Load `personal-assistant`; delegate to `assistant` |
| UI ideas, visual/interaction design, UX review or UI refinement | Load `impeccable` for the UI portion               |
| Explain, diagnose, compare, or investigate without edits        | [investigation](playbooks/investigation.md)        |
| Reproduce and fix a defect                                      | [bug fix](playbooks/bug-fix.md)                    |
| Add or change behavior                                          | [feature](playbooks/feature.md)                    |
| Preserve behavior while changing structure                      | [refactoring](playbooks/refactoring.md)            |
| Measure slowness or improve a metric                            | [performance](playbooks/performance.md)            |
| Settle an uncertain approach or write a requested plan          | [design](playbooks/design.md)                      |
| Large migration, unfamiliar run, or unattended work             | Load `figure-it-out`                               |
| Attack a completed code diff                                    | [attack the diff](playbooks/attack-the-diff.md)    |
| Open a PR, address reviews, fix checks, or land work            | [PR work](playbooks/pr-work.md)                    |
| Resume, report status, or pause                                 | [continuity](playbooks/continuity.md)              |
| Create, adapt, or evaluate a skill                              | [skill authoring](playbooks/skill-authoring.md)    |

An explicit skill command uses that skill's scope and stopping point. A follow-up continues the
active task. A new goal re-routes. A question about status does not cancel ongoing implementation.

The UI route applies when the requested outcome involves the interface's appearance or interaction
design: a screen, layout, typography, UX copy, accessibility, responsive behavior or motion. Merely
editing frontend code does not trigger it. Backend work, architecture discussions, security audits,
data-fetching fixes and behavior-preserving frontend refactors use their normal playbooks unless the
user also requests a UI change. Mixed tasks load Impeccable only for that portion and reuse this
workflow's final integration and code-review boundary.

Personal budgeting, mail and notebook work uses the assistant route without coding design,
repository bookkeeping or attack-the-diff. A request to change the Actual Budget/AFFiNE/Google
service configuration or integration code uses its normal coding playbook.

For a named principle, read [the principle reference](references/principles.md) as needed.

## Working principles

- Trace the current behavior before a nontrivial edit. Use `how` at the needed depth and `why` when
  history or motivation changes the design constraints.
- Choose the data shape and owner before branching logic. Validate external data once at its
  boundary; trust the internal model. Delete obsolete paths and migrate their callers together.
- Prefer deletion and direct code. A new wrapper, compatibility mode or dependency must solve an
  observed problem. Repeated failed fixes call for testing their shared premise.
- Use `architect` when ownership, public contracts or state modeling need a real decision. Crossing
  a function call alone does not require a design panel.
- Test empirical questions with a small probe. Ask the user for product intent or authority that
  evidence cannot supply. Existing approval remains approval.
- Verify a coherent unit before depending on it. Batch cheap related checks; run expensive shared
  gates at integration boundaries. Use the project's native language and test framework.
- Use `deslop` inline for the final code diff and `no-comments` when comments need a real pass.
  Preserve non-obvious rationale and constraints. Use `unslop` for substantive prose, not as an
  extra tool call on every status sentence.
- If the project lacks a repeatable way to drive the changed behavior, use
  `create-verification-skill` when that investment serves the task. Use
  `maintain-verification-skill` for drift in an existing recipe. Do not invent a test stack for a
  trivial edit.
- Check the real artifact or consumer path. Report evidence, failures and gaps. A green compiler, a
  worker's claim or a source-string assertion cannot prove behavior.
- Use `benchmark-checklist` for measured claims, `blast-radius` for consequential cross-boundary
  changes, and `interrogate` for contested or risky changes needing an adversarial pass. For
  substantive code changes, run [attack the diff](playbooks/attack-the-diff.md) at the completed
  review boundary: `deslop`, `no-comments`, `interrogate`, then
  `thermo-nuclear-code-quality-review`. Correctness and structural quality are distinct checks.

## Runtime and delegation

Use OpenCode's advertised tools and skill discovery. In OpenCode, load skills with `skill`, use
`todowrite` when useful, and dispatch `general`, `explore` or `reviewer` through `task`. The
configured prompt files define those roles. Do not send Cursor-only model slugs, background, cloud,
resume or read-only fields to an incompatible tool.

Workers inherit the active model unless the operator configured a role model. Do not change model,
reasoning or budget settings as a side effect. A same-model review is independent work, not a
multi-model verdict. State unavailable model diversity when it matters.

Keep a small, clear task inline. Use `swarm` for independent coverage and `arena` for competing
approaches. Give writers disjoint files or separate worktrees. Only the primary coordinates; workers
do not launch workers. Read their actual artifacts, integrate and verify.

## Authority and finish

The request authorizes the work it asks for. It does not authorize unrelated messages, commits,
pushes, merges, deployments or access changes. Follow the repository's concrete boundaries. Do not
manufacture approval checkpoints for reversible implementation.

Finish at the requested result. Explain what changed for its consumer, why this approach, the checks
and their outcomes, and any remaining prerequisite. Do not automatically open a PR or add
unrequested work. Keep a decision trail only when continuity or an unattended run needs it.
