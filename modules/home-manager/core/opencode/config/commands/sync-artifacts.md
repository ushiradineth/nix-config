---
description: Detect and resolve upstream-downstream artifact drift
agent: builder
---

Run artifact synchronization checks using args: `$ARGUMENTS`.

GPT-5.5 intent: keep source-of-truth artifacts, downstream implementation, and final claims aligned.

Default workflow role:

- Builder applies this methodology implicitly when planner-selected execution gates mark
  `sync-artifacts` as required.
- Use this command only as an optional manual override for explicit control or debugging.

Success criteria:

- Candidate source-of-truth and downstream artifacts are named.
- Drift is classified as none, minor, or material.
- Material drift has an update order that starts from the source of truth.
- Verification checks prove coherence after updates.

Output:

1. `Scope map`: upstream and downstream artifacts.
2. `Drift table`: mismatch type, severity, and affected files.
3. `Update order`: exact sequence to restore coherence.
4. `Verification checklist`: concrete checks after synchronization.

Stop rules:

- Stop if source-of-truth intent conflicts with implementation and cannot be reconciled.
- Do not silently rewrite source-of-truth intent.
- Keep unrelated artifacts out of scope.
