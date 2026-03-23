---
name: verification-before-completion
description:
  Use before any completion claim, commit, or PR update. Require fresh command evidence before
  saying work is done or passing.
---

# Verification before completion

## Core rule

No success claim without fresh verification evidence.

## Gate

Before claiming complete, fixed, or passing:

1. Identify the exact command that proves the claim.
2. Run the command now.
3. Read output and exit status.
4. Compare evidence to claim.
5. Report factual status with command evidence.

If evidence is missing, state status as unknown.

## Required moments

Apply this skill before:

- saying tests pass
- saying a bug is fixed
- opening or updating a PR with success claims
- final task completion reports

## Output contract

Return:

1. `Claim`: what is being asserted.
2. `Evidence`: command and key output.
3. `Result`: pass, fail, or unknown.
4. `Next action`: fix path if not pass.

## Anti-patterns

- "should pass" or "likely fixed" language
- relying on old command output for new claims
- skipping verification to save time
