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

UI design, brainstorming, interface review and visual/interaction fixes automatically use
`impeccable`; ordinary development does not. `/impeccable <technique> <target>` selects a design
move explicitly. Its `init`/`teach` arguments capture product context, while top-level `/init` still
creates repository guidance and `/teach` explains code. Review and brainstorming commands remain
read-only unless the user also requests implementation. Do not suggest the whole UI sequence for a
small fix or claim the upstream live-picker/detector is installed.

Distinguish `how` from `why`, `arena` from `swarm`, `blast-radius` from `interrogate`, and `ketchup`
from resuming work. Models live in managed opencode.json; workers inherit unless configured
otherwise. A model or harness change takes effect after the authorized apply and restart.

Help stays read-only. Do not begin implementation, run setup, change budgets, create a verification
skill or publish anything just because it was recommended.

Personal Actual Budget analysis and AFFiNE notes route to `assistant` using `personal-assistant`.
`/assistant` shows its menu; `/assistant <request>` performs the requested personal task. Actual
Budget is read-only. Requested AFFiNE note edits are read back, while drafts stay unsaved. Service
configuration changes use the engineering workflow. Setup uses `opencode-assistant setup` in the
user's terminal; do not request passwords in chat or claim a configured connector has account access
until a real read succeeds.
