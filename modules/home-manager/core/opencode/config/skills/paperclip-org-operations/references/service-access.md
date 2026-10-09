# Service and information access

## Access workflow

1. Describe the task capability, not a vendor credential: for example, "read upcoming calendar
   events" rather than "get a Google token".
2. Call `connections_search` for the service or capability before using any service tool, even when
   a connection appears to exist.
3. Follow the returned setup or usage instruction. If no usable connection exists, explain what is
   missing and ask the user to authorize or supply the required credential.
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

## Current Google access

The approved self-hosted connection exposes:

- Gmail read-only
- Google Drive read-only
- Google Calendar read-only
- OAuth identity scopes needed to identify the account

MCP endpoint: `https://google-mcp.shupi.ushira.com/mcp`

Use Paperclip's managed connection or gateway entry rather than placing this URL and OAuth material
inside prompts. The Google OAuth client secret remains in encrypted Nix secrets. User authorization
and refresh state stay in the MCP's persistent encrypted storage.

Before granting Dot access, verify the connection is healthy, authorize the intended personal Google
identity, bind only the read-only profile, and have Dot perform one read from each approved service.
Do not infer Gmail success from Calendar success.

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
