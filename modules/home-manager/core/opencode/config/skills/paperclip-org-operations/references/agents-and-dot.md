# Agents and Dot

## Role contract

Define these fields before creating or materially changing an agent:

- **Outcome:** the durable result the role owns.
- **Boundaries:** what it must not decide, change, or access.
- **Manager:** one accountable agent or the user; avoid ambiguous reporting chains.
- **Inputs:** issues, projects, connections, artifacts, routines, or user requests it may consume.
- **Outputs:** comments, decisions, documents, code, summaries, or external actions.
- **Trigger:** assignment, manual run, schedule, event, or delegated child issue.
- **Model:** the least expensive model that passes the acceptance task reliably.
- **Budget:** explicit spend and retry limits appropriate to the work.
- **Access:** no service access by default; add one capability at a time.
- **Acceptance test:** one realistic task with observable success and failure criteria.
- **Retirement condition:** when the role should be paused, merged, or removed.

Prefer improving an existing agent's skill or instructions when the missing behavior belongs to its
current outcome. Create a specialist when the work needs a distinct permission boundary, recurring
ownership, expertise, or independent review.

## Dot's operating role

Dot is the personal manager and primary user-facing coordinator. Dot should:

- turn requests into scoped Paperclip work with a named owner and completion evidence;
- answer directly when delegation adds no value;
- delegate specialist work through child issues rather than informal background polling;
- keep the user-facing thread concise while preserving evidence in the task or artifact;
- surface decisions, approval requests, access needs, and blockers early;
- maintain recurring personal workflows only after the user approves their schedule and authority;
- track migrations and operational chores until verification is complete;
- avoid acting as every specialist or silently expanding its own permissions.

Dot may receive read-only Gmail, Drive, and Calendar access through the approved Google connection.
Sending mail, modifying files, changing events, or sharing data requires separate explicit scope and
approval. Dot must use `connections_search` before service calls and follow the returned connection
instructions.

For the official Google integration migration, Dot owns the recurring compatibility check and may
open the migration task when all requirements are proven. Dot must not disable the self-hosted MCP
or request broader scopes without user approval.

## Agent configuration

Keep base instructions role-focused. Put reusable procedures in skills and task-specific facts in
issues or project documents. Avoid copying the same long policy into every agent prompt.

Model routing defaults:

- Use `gpt-6-luna` for short summaries, classification, title generation, and tightly bounded
  recurring checks when it passes evaluation.
- Use a stronger compatible model for ambiguous planning, multi-source synthesis, migrations,
  security-sensitive operations, or repeated tool failures.
- A model chosen as OpenCode's `small_model` is a useful hint, not proof that it is sufficient for a
  Paperclip role.

Set timeouts for work that can hang. Set budgets and retry ceilings for recurring agents. Enable raw
provider tracing only for a bounded diagnosis, then turn it off.

## Skill assignment

Assign skills by capability, not by convenience:

- All agents that can operate Paperclip organization state should receive
  `paperclip-org-operations`.
- Dot should receive it because Dot coordinates agents, access, routines, and migration work.
- Summarizer should retain `summarize-status`; this operational skill must not turn Summarizer into
  an organization administrator.
- A skill does not grant authority. API scopes, tool profiles, connection grants, and task context
  remain the actual permission boundary.

After assigning a skill, run one bounded task and inspect the run's skill inventory or startup
notes. Installation in the company catalog alone does not prove an agent received it.

## Review cadence

Review active agents regularly for:

- work completed versus repeated planning or retries;
- unresolved failures and model/authentication incompatibility;
- duplicated roles, unclear ownership, or circular delegation;
- unused or excessive service access;
- stale routines, excessive token use, and missing timeout or budget controls;
- instructions that contain mutable facts better discovered at runtime;
- outputs without a durable artifact, task update, decision, or external result.

Pause an agent before destructive retirement. Preserve useful skills, decisions, and artifacts;
reassign open work; revoke connections and secrets that no remaining role needs; then remove the
role only after the user approves it.
