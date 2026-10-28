# Bug fix

1. Reproduce the reported behavior on the relevant CLI, app, service or native test seam. Record the
   actual failure. If the target is unavailable, name the missing prerequisite and use the nearest
   honest check without claiming to have reproduced it.
2. Trace the first incorrect state with `how`, relevant history and one hypothesis at a time. Add
   temporary instrumentation only when it answers a question; remove it before delivery.
3. Use `tdd` when there is a cheap meaningful regression seam. Fix the evidenced cause. Use
   `architect` only if the fix needs a new contract, owner or state shape.
4. Rerun the original reproduction and affected checks. Run required repository gates after the
   coherent fix. Remove speculative changes that the evidence did not justify.
5. Run [attack the diff](attack-the-diff.md), then report symptom, cause, fix, and
   failing-then-passing evidence. Commit or open a PR only when requested.
