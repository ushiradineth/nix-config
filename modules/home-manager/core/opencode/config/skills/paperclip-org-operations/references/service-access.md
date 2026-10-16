# Service and information access

## Access workflow

1. Describe the task capability, not a vendor credential: for example, "read upcoming calendar
   events" rather than "get a Google token".
2. Call the semantic `connections_search` tool for the service or capability before using any
   service tool, even when a connection appears to exist. If the current runtime does not advertise
   it, use an authorized board or company-scoped connection inventory instead of guessing a callback
   route.
3. Follow the returned setup or usage instruction. If no usable connection exists, explain what is
   missing and ask the user to authorize or securely provide the required credential.
4. Prefer OAuth or device authorization. For API keys and passwords, use Paperclip's secure secret
   or connection input rather than issue comments, prompts, shell history, or repository files.
5. Request the smallest scopes and bind access only to the agent or group that needs it.
6. Test one harmless operation through the same agent-visible path that production work will use.
7. Record the connection, identity, scopes, grantees, test evidence, owner, and revocation path.
8. Review and remove stale grants after migrations, role changes, or agent retirement.

It is acceptable to ask for credentials when access cannot be established otherwise. Be direct about
what is needed and why. Never ask the user to post a credential in a public issue or normal agent
comment. If a credential is supplied in an unsafe channel, do not repeat it; move it into the
approved secret store and recommend rotation when exposure is material.

Make the request one concise question. Name the service and identity, the exact read or write
scopes, where authorization must happen, where Paperclip will store the result, which agent receives
it, and the harmless test that will follow. Ask the user to complete the secure authorization flow,
not to paste a token, password, OAuth code, or secret into the conversation.

## Secret requests and proposals

Use Paperclip's proposal API when the requested access can be represented by a real secret or an
existing binding. Search for `secret proposal` with `search_api`, then use the exact
`POST /api/agents/me/secret-proposals` operation ID returned by the catalog with `call_api`.

- If the secret is already bound to the proposing agent, submit `kind: "binding"` with its existing
  `sourceConfigPath`, the required `configPath`, a concise justification, and `targetAgentId` only
  for an authorized report. Paperclip creates the human-only confirmation card automatically.
- If a credential arrives from an approved secure source, submit `kind: "secret"` immediately and
  pass the value directly from memory or that source. Never place the value in a comment, document,
  file, transcript, shell argument, or tool narration. Then submit the required binding proposal.
- If the credential value is not available, do not invent a placeholder or claim that an empty
  secret proposal was created. Paperclip secret proposals require a value. Use `request_human_input`
  with `continuationPolicy: "wake_assignee"` to ask the user to create or bind it through
  Paperclip's Secrets UI, naming the service, identity, least-privilege access, destination `env.*`
  or `access.*` path, grantee, reason, and harmless follow-up test. Tell the user to answer only
  when setup is ready and never to enter the credential in the response.

Use a confirmation card for this request, not a one-option question. On runners that scan semantic
tool text, descriptive wording can look like a supplied value. Use this detector-safe shape, replace
the angle-bracket placeholders, and do not add option descriptions or extra tool fields:

```json
{
  "idempotencyKey": "<service>-<config-path>-setup-v1",
  "interactionKind": "confirmation",
  "title": "<service> setup",
  "prompt": "Open Paperclip Secrets. Add the <service> entry. Bind <grantees> at <config-path>. Select Confirm only after setup. Do not include the value.",
  "continuationPolicy": "wake_assignee"
}
```

Keep the config path sentence-final before punctuation. The card must identify the service, intended
identity, minimum access, grantees, reason, and harmless test either in the substituted prompt or in
the task context. Never include the missing value.

After a proposal card resolves, list agent-visible secret metadata again and verify the expected
binding exists. An accepted card is not proof of execution; missing metadata or a failed execution
status remains blocked.

Verify delivery in the consuming runtime separately. A successful adapter secret manifest or binding
at `env.*` does not prove that a runner-mediated shell tool inherits that environment. Check
presence without values through the supported runtime, then prove the authorized service operation.
Do not dump `env`, print secret values, or copy a value into commands/files to work around missing
delivery. Report binding, delivery and service authentication as separate results.

## Permission tiers

- **Tier 0, public:** public web pages and documentation.
- **Tier 1, private read:** mail, files, calendars, notes, metrics, and internal APIs without
  writes.
- **Tier 2, controlled write:** create or update content without deletion, sending, billing, or
  administration.
- **Tier 3, consequential:** send, delete, publish, deploy, purchase, administer, or change access.

Default to the lowest tier that completes the task. Moving to a higher tier requires explicit user
approval, a stated test, and a revocation path. A read-only grant to one agent does not authorize
sharing it with all agents.

## Live Obsidian vault

The live vault is on the macOS host `shu` at `/Users/shu/Documents/Obsidian Vault`. Paperclip's
local Linux worker on `shupi` does not have that Mac filesystem. Use the existing `ssh shu` route
for every vault directory check, listing, search, and note read; this also works when managed runs
use an isolated home because SSH configuration is provided through `/etc/ssh`.

Verify the remote directory first:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 shu 'test -d "/Users/shu/Documents/Obsidian Vault" && test -r "/Users/shu/Documents/Obsidian Vault" && ls -ld "/Users/shu/Documents/Obsidian Vault"'
```

- Quote paths with spaces inside the remote command. Read only notes needed for the authorized task;
  do not copy or export the whole vault or expose note contents in diagnostic reports.
- Preserve personal, Surge, and Jellybyte boundaries. Knowing the route does not grant access to
  private health/financial notes or permission to write. Keep report-only roles report-only.
- A missing local `/Users` means the command ran on the wrong host, not that a vault mount is
  missing. If access fails, report the remote host, attempted path, and exact SSH/permission/path
  error after testing `shu`.
- Do not restore a mount, copy/sync the vault, switch execution environments, relax SSH host-key
  checking, or change Obsidian settings as a workaround. Those changes require separate approval.
- Include this host-qualified locator and SSH-first rule in new role instructions when the role
  needs vault context; never give a bare Mac path without its host and access method.

## Current Google access

Always use the existing Paperclip connection named `Google MCP` for Google services. Do not request,
create, or fall back to Paperclip's built-in Google Drive, Gmail, Calendar, Docs, or Sheets
connectors; those connector paths are not supported on this instance. If `connections_search`
returns multiple Google options, choose `Google MCP`. If it is missing or unavailable to the current
agent, ask the board to grant or repair that exact connection instead of opening a built-in Google
connector setup flow.

The server provides Gmail, Drive, Calendar, Docs and Sheets tools. Discover current OAuth consent,
agent profiles, action policy and task approval before selecting reads or writes. A cataloged write
tool or broad provider scope does not authorize sending, deletion, sharing, calendar changes or
financial actions. An approval-required rename failure is not evidence of an invalid filename or
insufficient file sharing; inspect the action-policy result before changing either.

MCP endpoint: `https://gmcp.shupi.ushira.com/mcp`

Use Paperclip's managed connection or gateway entry rather than placing this URL and OAuth material
inside prompts. The Google OAuth client secret remains in encrypted Nix secrets. User authorization
and refresh state stay in the MCP's persistent encrypted storage.

Verify the connection, intended identity and least-privilege grant, then perform the smallest
authorized operation in the target agent's runtime. Test separately approved writes without
inventing transactions or messages. Gmail success does not prove Drive, Calendar, Docs or Sheets
success.

### File transfers and retention

For an approved attachment import, fetch current Gmail attachment metadata and call
`get_gmail_attachment_content` with `return_base64=false`. Pass its temporary MCP download URL as
`create_drive_file.fileUrl`, or use the matching supported update/import/attachment parameter. The
maintained connector resolves its own URL locally as an account-bound handle, with expiry and
integrity checks; it does not make an HTTP request to the private tailnet address. Drive downloads,
Gmail message exports and supported Chat downloads use the same store.

- Re-fetch expired or post-restart handles; do not preserve them in durable artifacts or pass them
  to another account. Direct HTTP downloads require the owner's MCP OAuth authorization.
- Verify current source/destination metadata before import and confirm the returned Drive ID and
  size afterward. Keep a source-to-copy receipt log. Preserve earlier successful imports and
  archives when resuming partial work; exact-name checks alone do not prove content deduplication.
- The current Nix source caps files at 16 MiB on a 64 MB tmpfs. Report size/capacity errors instead
  of enlarging limits, returning full base64 or changing storage/security controls without approval.
- Archive means removing `INBOX`, not trashing or deleting. Verify labels, keep per-message
  evidence, and obtain separate approval for deletion, sending or sharing changes.

### Gateway failure diagnosis

Check service health, Paperclip connection health, catalog state and the specific method separately.
An active connection or healthy `/health` response does not prove a cataloged method can execute.

- `tool_not_found` with an active catalog entry: use an authorized harmless method probe to
  reproduce dispatch, then refresh that connection's catalog only when repair is authorized. Verify
  the exact method again before waking the task; do not loop on agent retries or create a duplicate
  connector.
- A read-only probe using an intentionally invalid ID can prove dispatch without opening a record.
  An expected provider error proves routing only. Inspect tool-result errors even when HTTP is 200.
- `mcp_remote_response_too_large`: inspect the response-size limit for the deployed Paperclip
  version; encoded bytes and framing can exceed it even when the raw file is smaller. Use the shared
  file-handle path, not a blanket gateway-limit increase.
- `Stateless mode: File storage disabled`: the server cannot issue a usable stored-file handle.
  Compare the deployed storage mode and writable home with the Nix definition; production changes
  require approval. Stateful mode needs writable directories despite a read-only container root.
- Private/internal URL rejection: unrelated private URLs must remain blocked. An own-server handle
  rejection can indicate a missing/stale connector patch; verify the deployed image and fresh
  handle. Do not rewrite the URL, expose the endpoint publicly, use `file://`, enable arbitrary
  local files or disable SSRF protection.

## Actual Budget access

Use the reachable server URL from the Nix/service configuration and a compatible official
`@actual-app/api` client. The sync server is not a general REST budget CRUD API. The client uses a
private local cache and the selected budget's Sync ID; ask the user to select a budget when the
identity is ambiguous, and obtain any required encryption secret through approved secure delivery.

A healthy server, password-login availability, accepted setup card or `env.ACTUAL_BUDGET_PASSWORD`
binding proves only that layer. Verify credential delivery, client compatibility, selected budget
download and a harmless read in each authorized consuming runtime. Do not treat another agent's
success as finance-role access, claim a reconciled baseline without sources, or create test
transactions to prove authentication. Keep personal and company finances separate; edits and
financial actions still need their own approved scope.

## Connector migrations

Run old and new integrations in parallel until parity is proven:

1. Verify the official connector supports the intended account type, not just the provider in
   general.
2. Compare scopes and reject silent permission expansion.
3. Authorize the new connector through the supported user flow.
4. Test representative reads and any separately approved writes.
5. Move one agent first, observe it, then widen the binding.
6. Obtain explicit approval before disabling the old connector.
7. Revoke old credentials and remove obsolete secret wiring only after the observation period.

For Google, consumer Gmail support without Workspace Developer Preview is a required migration gate.
Documentation alone is insufficient; prove it with the installed Paperclip version and the intended
account.

## Information architecture

Choose the narrowest durable home for information:

- Organization-wide operating procedure: company skill.
- Role-specific behavior: agent instructions or role skill.
- Current work and decisions: issues, comments, approvals, and project documents.
- Reusable deliverables: artifacts.
- External live data: service connection, queried when needed.
- Infrastructure settings: Nix configuration.
- Credentials: secret provider or encrypted secret store.

Do not turn prompts into databases. Store a pointer and discovery method when the source changes
frequently.
