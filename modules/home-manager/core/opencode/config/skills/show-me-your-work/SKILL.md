---
name: show-me-your-work
description:
  "Keep a compact decision and evidence trail for long or unattended work, or audit that trail when
  requested."
license: MIT
---

# Show me your work

Use a task-local decision log when work spans phases or sessions, or the user asks for an audit
trail. Do not create one for routine fixes. Record decisions, discarded hypotheses and verification
boundaries, not every file edit or tool call.

Use the TSV columns in [the template](references/decision-log-template.tsv): `ts`, `phase`,
`decision`, `why`, `evidence`, `result`. Append with
`bash <skill-dir>/scripts/log.sh <logfile> <phase> <decision> <why> <evidence> <result>`. The
[helper](scripts/log.sh) stamps UTC time, preserves rows and neutralizes spreadsheet formulas. Each
entry carries time, decision, reason, evidence location and result. Record an exact command, commit
or artifact where it matters to reproduce the result. Keep secrets out. The log stays local unless
the user requests it in the deliverable or commits.

Update at meaningful checkpoints and before a handoff. A resume note names the goal, current branch
and dirty state, completed proof, open blockers and next action. Shared log writes belong to the
primary; workers return their receipts.

Logs are append-only. Correct a wrong row with a superseding entry. Name the run and inherited range
when continuing an existing trail.

For an audit, read the trail and actual artifacts. Check entries against the current conversation or
an explicitly supplied OpenCode session export; do not search unrelated session storage. Separate
recorded claims from checked facts. Return the consequential choices, evidence and items deserving
scrutiny. An independent reviewer can help on high-stakes runs; do not require a panel to summarize
a small log.
