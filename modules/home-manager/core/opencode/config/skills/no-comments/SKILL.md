---
name: no-comments
description:
  "Review scoped code comments, remove narration and preserve necessary rationale, API
  documentation, licenses and external constraints."
license: MIT
---

# No comments

Review the caller's files or diff. Look for comments that narrate obvious code, excuse dead paths,
repeat types, hide a workaround or mark a constraint that could be encoded.

Use a fresh `reviewer` for a disputed or consequential comment pass, or when an independent attack
was requested. Routine bounded cleanup can stay inline. The reviewer remains read-only. Include the
actual diff, intent and this keep list:

- license and attribution notices;
- useful public API documentation;
- non-obvious rationale or evidence links the code cannot express;
- constraints imposed by external systems or protocols;
- required compiler, linter or tool directives whose necessity is verified.

Remove accepted narration within scope. If a comment reveals a design flaw, inspect the root cause
and fix it only within the authorized task. Do not turn comment cleanup into an unrequested rewrite.

Never delete a real constraint or correctness suppression simply because its enforcement needs work.
Verify it first, preserve the rationale, and encode it in a type, test or check when that is a
justified in-scope change. Respect generated files and exact strings. Report material removals,
encoded constraints and unresolved concerns; do not require an exhaustive deletion ledger.
