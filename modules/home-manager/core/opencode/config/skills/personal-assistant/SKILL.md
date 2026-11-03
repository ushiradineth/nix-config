---
name: personal-assistant
description:
  "Use when reviewing personal spending, budgets, subscriptions or tax preparation records in Actual
  Budget, or finding, creating and editing personal notes, plans and reviews in AFFiNE. Also use for
  combined budget-to-notebook reviews. Service configuration, migrations and other software changes
  use the coding workflow. Health integrations are not configured."
---

# Personal assistant

Use Actual Budget for financial facts and AFFiNE for durable notes. Keep a small request small:
answer a question, update the requested note, or produce a review with traceable inputs. Skip coding
plans, attack-the-diff, UI design and project `.agents` bookkeeping for personal work.

## Select the source

In `jiyu`, delegate the personal request to `assistant`, carrying the user's scope, relevant facts
and existing authorization. The service tools are available only there. `/assistant` and
`@assistant` also select it directly. In `assistant`, execute the request without another handoff.
Changing the Nix service, connector code or harness itself stays with `jiyu`.

Use only the service needed. For a combined task, keep Actual Budget as the source of numbers and
save the requested synthesis in AFFiNE. Do not copy raw transactions or entire workspaces into notes
or logs when an aggregate answers the question. Finance and note data sent through tools is visible
to the configured model; a local connector is not an offline model.

## Establish access and identity

The configured prefixes are `actualbudget_` and `affine_`. Discover their advertised schemas; do not
guess argument shapes. Setup and connection checks are in [connections](references/connections.md).

For a finance request, start with `actualbudget_actual_get_context`. Confirm the selected budget,
currency, coverage and relevant accounts. The setup pins one budget Sync ID; do not switch to
another budget, include company accounts or trigger bank sync to fill missing data. The connector
enforces read-only access. If the user requests transaction edits, explain this limit and present
the proposed edits without attempting a shell or direct-API bypass.

For AFFiNE, use the configured workspace when present; otherwise list accessible workspaces. Use the
only workspace if unambiguous, or ask the user to choose when several could fit. Resolve a note by
title/search, then read it before editing. Ask only when duplicate candidates cannot be resolved
from the request and content. Keep the workspace and document IDs for this task.

## Budgeting and tax preparation

- Resolve the date range, currency and account scope. Use the data's currency units; Actual stores
  amounts in minor units. Check the tool's output before converting, and avoid converting twice.
- Prefer a bounded aggregate or query over loading every transaction. Account for transfers,
  refunds, split transactions, excluded/off-budget accounts and incomplete imports. Do not treat a
  transfer as spending or invent an exchange rate for mixed currencies.
- Separate recorded transactions, budget allocations and inferred patterns. A recurring charge is a
  subscription candidate, not evidence it is unused. Net worth needs the relevant asset and
  liability balances. An apparent tax category does not prove deductibility.
- Include the period, source budget/accounts, data coverage and assumptions with the result. Reuse a
  result when its inputs are unchanged; do not imply a bank reconciliation or a live bank feed.
- For tax preparation, establish filing jurisdiction, tax year, residency and personal/business
  scope before applying rules. Use current official tax-authority sources for legal claims. Gather
  records and identify gaps; filing, payments and external submissions need their own request.

## AFFiNE notes and reviews

A request to find, analyse or draft stays read-only. A request to create, append, update or save
authorizes that concrete note change without a second approval. Do not turn a normal budgeting
question into an unsolicited weekly report or scheduled automation.

For a requested new note, check for an existing matching note, create the document with the provided
content, then read it back. For an existing note, preserve unrelated blocks and prefer
`append_markdown`, `update_block` or `update_doc_title`. Pass the `read_doc` revision as
`expectedRevision` whenever the mutation's schema accepts it. If it is stale, reread and reconcile.
The configured profile omits full-note replacement, deletion, publishing and account management.

Verify the changed content through a fresh read and return a document link using its real
workspace/document IDs. If a write times out or reports partial success, inspect the note before
retrying so an append or create is not duplicated. A transport acknowledgement alone does not prove
the content persisted.

For a combined monthly review, include the period, budget source, a few supported findings and the
user's chosen actions. Keep evidence sufficient to reproduce the numbers without copying account
identifiers or detailed spending into the notebook unnecessarily. Report missing access or data
coverage clearly; finish any independent draft that the available information supports.
