---
name: correct
description:
  "Fix a demonstrated repeated agent mistake at its source using architecture, types, checks or
  behavioral tests before adding more prompt rules."
license: MIT
---

# Correct

Use the user's named mistake or find a repeated class in relevant commits, reverts and review
feedback. Cite the occurrences. One unusual session is not automatically a universal rule.

Choose the highest effective fix: eliminate the invalid path through ownership or data modeling,
reject it with types or a focused lint, catch its observable behavior with a test, then document
only the judgment a tool cannot enforce. Prefer existing checks over another custom validator.

Prove the proposed enforcement rejects a real example of the mistake while accepting correct code.
Use the component's language and test framework. Do not assert prompt wording as a proxy for
behavior.

Keep changes scoped to the demonstrated class and current request. Do not rewrite global skills,
open tickets, change CI policy or commit one fix per class unless the user requested those actions.
Return the evidence, structural correction, proof and any judgment that remains.
