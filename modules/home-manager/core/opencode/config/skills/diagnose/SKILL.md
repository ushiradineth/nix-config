---
name: diagnose
description:
  Use for hard bugs, failing checks, pipeline failures, homelab incidents, performance regressions,
  or reports that something is broken and needs root-cause analysis.
---

# Diagnose

## Core rule

Build a feedback loop before theorizing. A fast deterministic pass or fail signal is the main tool.

## Workflow

1. Reproduce or create the closest runnable signal:
   - failing test
   - CLI command
   - curl or HTTP script
   - log query
   - minimal harness
2. Confirm the signal matches the user's symptom.
3. Generate 3 to 5 falsifiable hypotheses.
4. Test one variable at a time.
5. Add targeted temporary instrumentation only when needed.
6. Fix the confirmed cause.
7. Add a regression test when there is a correct seam.
8. Remove temporary instrumentation and rerun the original signal.

## Debug logging

- Use a unique prefix such as `[DEBUG-abc123]`.
- Remove it before completion.
- Never log secrets.

## Stop condition

If no feedback loop can be built, report what was tried and ask for the missing artifact or access.
