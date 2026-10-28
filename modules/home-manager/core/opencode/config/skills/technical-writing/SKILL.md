---
name: technical-writing
description:
  "Write or review docs, RFCs, readmes, PR descriptions and commit messages so the reader can act or
  understand on the first read."
license: MIT
---

# Technical writing

Choose the document's job: tutorial for learning by doing, how-to for a concrete task, reference for
lookup, or explanation for understanding. Keep unrelated jobs in linked sections or separate files.

Use the actual codebase's nouns, paths, flags and commands. Ground procedures in verified commands.
Say what the reader should see after a step. Put prerequisites and consequences before the action.
Name who does what, use familiar words, and keep each sentence's reference clear.

Number ordered steps. Use bullets for parallel facts and tables for comparisons. Keep examples
complete enough to run without inventing values that look real. Mark placeholders explicitly.
Preserve exact facts, links, quotations, API contracts and required formats.

Use `unslop` for generic AI phrasing and `personal-writing-identity` only when the task asks for
Shu's voice. Avoid a forced draft/audit/final loop. Write the finished artifact and verify its
claims, commands and links. PR descriptions lead with the concrete problem, resulting behavior and
checks.
