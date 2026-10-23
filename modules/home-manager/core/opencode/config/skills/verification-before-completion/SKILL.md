---
name: verification-before-completion
description:
  Use before any completion claim, commit, or PR update. Require fresh command evidence before
  saying work is done or passing.
---

# Verification before completion

## Core rule

No success claim without verification evidence covering the current relevant inputs. Freshness is
about those inputs, not how recently the command ran or how often a claim is repeated.

## Gate

Before claiming complete, fixed, or passing:

1. Identify the smallest command or direct inspection that proves the claim.
2. Reuse evidence from this task if it covers the current relevant source, tests, dependencies,
   configuration and environment. Otherwise run the needed check at the completed batch boundary.
3. Read the evidence, including command output and exit status when applicable.
4. Compare evidence to claim.
5. Report factual status with command evidence.

If evidence is missing, state status as unknown.

## Cadence

- Follow the shared contract's risk-based batching policy. This skill is a claim gate, not a reason
  to run a suite after every edit, progress update or final-answer draft.
- One successful aggregate run can support multiple covered claims. Do not rerun its component
  commands just to collect separate receipts.
- After subsequent edits, invalidate only affected evidence. A source change needs the checks that
  cover it; an unrelated prose edit does not invalidate a runtime test. Honor explicit repository,
  accepted-plan and publication gates.
- Prompt/docs-only work can use scoped formatting and content/coherence inspection. That proves
  source quality, not live agent behavior; report runtime behavior as untested unless exercised.

## Required moments

Apply this skill before:

- saying tests pass
- saying a bug is fixed
- opening or updating a PR with success claims
- final task completion reports

## Output contract

Return:

1. `Claim`: what is being asserted.
2. `Evidence`: command/tool/inspection and key result; identify reused evidence when material.
3. `Result`: pass, fail, or unknown.
4. `Next action`: fix path if not pass.

## Anti-patterns

- "should pass" or "likely fixed" language
- relying on output from a previous session or inputs changed since the check
- omitting relevant verification, or rerunning unchanged checks just to make evidence newer
