---
name: paperclip-org-operations
description:
  Use when operating, maintaining, troubleshooting, or expanding Shu's self-hosted Paperclip
  organization; managing Dot or another agent; creating roles, routines, goals, or projects;
  choosing agent models; connecting agents to services or information; requesting credentials;
  reviewing permissions; or planning a connector migration. Consult this skill for any Paperclip
  org, agent, access, or governance work, even when the request is phrased as "fix Paperclip", "grow
  the org", "give Dot access", or "hire an agent".
---

# Paperclip organization operations

Operate Paperclip as a controlled organization, not a collection of autonomous prompts. Keep the
instance reliable, give each agent a clear job, make Dot a useful front door, and expand access only
as far as the work requires.

## Load the right context

Read `references/instance.md` for every Paperclip task. Then load only the relevant branch:

- Agent creation, configuration, models, maintenance, or Dot: `references/agents-and-dot.md`
- Connections, credentials, MCP, OAuth, data, or service permissions: `references/service-access.md`
- Goals, projects, delegation, routines, capacity, or organization growth:
  `references/org-growth.md`

The references contain current known facts and durable policy. Verify mutable state through
Paperclip before acting; IDs, versions, installed skills, models, connections, and agent status can
change.

## Operating contract

1. Map the request to an explicit outcome. Do not infer permission for adjacent cleanup, new agents,
   new credentials, write scopes, schedules, or production changes.
2. Read live state through Paperclip's scoped API, CLI, OpenAPI schema, or connection tools. Use the
   database and persistent filesystem only for diagnosis or recovery when the user explicitly asks
   for host-level operations.
3. Choose the smallest control-plane change that can produce the outcome.
4. Preview the affected agent, skill, connection, routine, scope, model, and rollback path before a
   material mutation.
5. Execute once, then verify with direct evidence from the same surface the agent will use.
6. Record what changed, why, who owns the next step, and any remaining uncertainty.

When running inside an agent heartbeat, derive the API base without duplicating `/api`:

```sh
PAPERCLIP_API_BASE="${PAPERCLIP_API_URL%/}"
PAPERCLIP_API_BASE="${PAPERCLIP_API_BASE%/api}"
```

Use the run-scoped `PAPERCLIP_API_KEY`, company ID, agent ID, and task ID already present in the
environment. Never print those values. Consult Paperclip's OpenAPI document before guessing a route
or payload.

## Runtime-aware tool use

Inspect the current run's adapter, environment, and advertised tool inventory before choosing an
operation. A skill may describe a semantic tool that the current runtime does not expose.

- Use a semantic Paperclip tool when it is advertised. It carries the active run, task, and user
  context without reconstructing a REST call.
- For task titles, call `set_task_title` early. Use a REST title route only when the semantic tool
  is absent and the live OpenAPI plus the current bridge allow that route. Do not retry a route
  after the bridge returns `Route not allowed`.
- For service access, call `connections_search` before any service tool. If it is absent, use an
  authorized board or company-scoped connection inventory; do not treat a bridge-denied connection
  route as proof that no connection exists.
- Report the exact missing tool, denied route, or runtime constraint when an operation is blocked.
  Distinguish runtime capability failures from authentication and permission failures.

Do not infer native execution from an enabled feature flag or a selected adapter. A bounded run must
show `paperclip_runner` dispatch and successful transport before native-only tools are considered
available.

## Authority and credential handling

Agents may ask the user for credentials when a required service has no usable connection. State:

- which service and identity need authorization;
- the exact capability and scopes required;
- whether access is read-only or permits writes;
- where the credential will be stored and which agents will receive it;
- how access can be tested and revoked.

Prefer OAuth or device authorization. Otherwise use Paperclip's secure secret or connection input.
If the user supplies a raw credential, move it into the approved secret store without repeating it
in comments, logs, prompts, tasks, artifacts, or commits. Never place credentials in this skill.

Require explicit user approval before:

- adding write, send, delete, billing, admin, or production permissions;
- sharing a connection with another agent or a wider group;
- hiring, deleting, or materially changing an agent's authority;
- enabling a recurring routine that can mutate external systems;
- changing budgets, manager relationships, deployment configuration, or secret wiring;
- disabling a working integration during migration.

Read-only inspection, health checks, inventory, and drafting a proposed change do not imply approval
to perform the mutation.

## Select the correct operating surface

- **Paperclip organization state:** use company-scoped Paperclip APIs or CLI commands.
- **Agent service access:** call `connections_search` first, follow its returned instructions, then
  use the installed connection. Do not assume a connection is usable because it exists.
- **Infrastructure and containers:** use the Nix configuration as source of truth and follow its
  deployment guardrails.
- **Agent knowledge:** prefer company skills, scoped instructions, project documents, and artifacts.
  Do not copy a large mutable knowledge base into every agent prompt.
- **Secrets:** use Paperclip secret providers, connection authorization, or encrypted Nix secrets.
- **Decisions requiring the user:** create a focused Paperclip interaction or ask directly; do not
  hide a consequential choice in an issue comment.

## Maintenance loop

For a maintenance request, check only the layers needed to answer it:

1. Instance health, deployment version, backup status, storage, and relevant container or service.
2. Failed, stalled, expensive, or repeatedly retried agent runs.
3. Agent model compatibility, authentication, instructions, skills, budgets, and schedules.
4. Connection health, OAuth expiry, granted scopes, policy bindings, and recent failures.
5. Open approvals, blocked issues, stale routines, and work without a clear owner.

Do not treat an active systemd unit as proof that an application works. Verify the application
endpoint or an agent-visible operation. For incidents, establish one deterministic red/green signal
before changing configuration.

## Organization growth loop

Grow from work, not from titles:

1. Identify an outcome Dot or an existing specialist cannot reliably own.
2. Decide whether a skill, clearer instructions, a routine, or a dedicated agent is the smallest
   solution.
3. If a new agent is justified, define its role contract, manager, inputs, outputs, permissions,
   model, budget, schedule, and acceptance test before creation.
4. Start with no external access, then add the minimum connection required for its first real task.
5. Give it one bounded trial task and review evidence before recurring or broader work.
6. Pause, narrow, retrain, merge, or retire roles that duplicate work or produce no durable output.

## Completion evidence

A Paperclip operation is complete only when the intended consumer can use it:

- agent changes: one bounded run succeeds with the expected model, instructions, and skill set;
- connection changes: the target agent performs the smallest authorized test call;
- routine changes: the schedule and next run are visible, and a manual run proves the behavior;
- skill changes: Paperclip shows the expected version and the intended agents receive it;
- infrastructure changes: service health and the external route are both verified;
- migrations: parity is proven before the previous integration is disabled.

Report partial or unknown status plainly. Never claim that a credential, permission, backup,
connection, or agent behavior works without direct evidence.
