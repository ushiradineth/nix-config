---
name: jiyu-help
description:
  "Explain this OpenCode seojiyu setup or choose a skill for a situation. Help only; do not start
  the suggested task."
license: MIT
---

# Jiyu help

Answer the user's question from the installed harness and skill inventory. Read the relevant skill
before explaining its behavior. For installation and local changes, read
`~/.config/opencode/HARNESS.md`. Do not give Cursor or Claude installation commands.

Normal work already uses the `jiyu` primary and `jiyu-mode`; the user describes a goal and how to
check it. Explicit slash commands choose one technique. Give one useful example, not a skill
sequence the router already owns.

Distinguish `how` from `why`, `arena` from `swarm`, `blast-radius` from `interrogate`, and `ketchup`
from resuming work. Models live in managed opencode.json; workers inherit unless configured
otherwise. A model or harness change takes effect after the authorized apply and restart.

Help stays read-only. Do not begin implementation, run setup, change budgets, create a verification
skill or publish anything just because it was recommended.
