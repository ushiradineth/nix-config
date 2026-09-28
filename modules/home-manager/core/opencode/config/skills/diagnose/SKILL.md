---
name: diagnose
description:
  Use for hard bugs, failing checks, pipeline failures, homelab incidents, performance regressions,
  or reports that something is broken and needs root-cause analysis.
---

# Diagnose

## Core rule

Build a feedback loop before theorizing. Phase 1 is complete only after one already-run command can
go red on the user's exact symptom and green after a fix.

Redact secrets from commands, outputs, traces, and captured artifacts. Use `<REDACTED>` in reported
evidence and keep credentials in environment variables.

## Workflow

1. Build the red-capable signal:
   - failing test
   - CLI command
   - curl or HTTP script
   - headless browser script
   - captured trace replay
   - minimal harness
2. Tighten it until it is fast, deterministic, agent-runnable, and specific to the reported symptom.
   For intermittent bugs, loop or stress the trigger until the reproduction rate is useful and
   recorded.
3. Reproduce, then minimize the scenario one element at a time. Every remaining input, caller,
   configuration, and step must be load-bearing for the failure.
4. Generate 3 to 5 ranked falsifiable hypotheses. State the prediction each hypothesis makes before
   testing it.
5. Test one variable at a time. Add targeted temporary instrumentation only when it distinguishes
   ranked hypotheses.
6. Add a regression test before the fix when a correct seam can reproduce the real bug pattern. If
   no correct seam exists, record that architecture limitation instead of adding a weak test.
7. Fix the confirmed cause, rerun the regression test, then rerun the original unminimized signal.
8. Remove temporary instrumentation and throwaway harnesses.

## Phase 1 gate

Before reading broadly for a cause, report:

- the one command already run
- the red output or exact failing symptom, with secrets redacted
- why the command can detect this bug rather than a nearby failure
- its runtime and determinism

No red-capable command means no hypothesis phase.

## Debug logging

- Use a unique prefix such as `[DEBUG-abc123]`.
- Remove it before completion.
- Never log secrets.

## Completion criteria

- The original signal is green.
- The regression test is green, or the missing seam is documented.
- No `[DEBUG-...]` instrumentation or throwaway harness remains.
- The confirmed cause and discriminating evidence are recorded.

## Stop condition

If no feedback loop can be built, stop. Report what was tried and ask for the missing access,
redacted artifact, or permission for temporary instrumentation. Do not proceed with speculative
hypotheses.
