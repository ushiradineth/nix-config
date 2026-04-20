---
description: Detect and resolve upstream-downstream artifact drift
agent: builder
---

Run artifact synchronization checks using args: `$ARGUMENTS`.

Use this command when execution decisions may have made strategy, plan, or source-of-truth artifacts
stale.

Default workflow role:

- Builder should apply this methodology implicitly when planner-selected execution gates mark
  sync-artifacts as required.
- Use this command as an optional manual override for explicit control or debugging.

Workflow:

1. List candidate source-of-truth artifacts in scope.
2. List downstream artifacts that implement or reference those decisions.
3. Compare key decisions, constraints, and numeric values across both sets.
4. Record drift as `none`, `minor`, or `material`.
5. For `material` drift, generate update order that starts from source-of-truth artifacts.
6. Produce a verification checklist that confirms coherence after updates.

Output contract:

Return all sections:

1. `Scope map`: upstream and downstream artifacts.
2. `Drift table`: mismatch type, severity, and affected files.
3. `Update order`: exact sequence to restore coherence.
4. `Verification checklist`: concrete checks after synchronization.

Safety gates:

- Do not silently rewrite source-of-truth intent.
- Escalate when conflicting requirements cannot be reconciled.
- Keep unrelated artifacts out of scope.
