# Personal assistant connections

Run the installed helper in the user's own terminal:

```sh
opencode-assistant setup actualbudget
opencode-assistant setup affine
opencode-assistant status
```

Setup prompts hide passwords. They save mode-0600 JSON under
`${XDG_CONFIG_HOME:-~/.config}/opencode-assistant/` in a private directory. Do not print, attach,
commit or copy those files into a prompt. `status` checks configuration, not authentication or
budget/document access. Missing credentials do not authorize extracting browser sessions or
modifying server authentication. The helper uses pinned Nix-packaged connectors, without runtime
package downloads or a public MCP listener.

Actual Budget defaults to `https://ab.shupi.ushira.com`. Supply the server login password and the
personal budget's Sync ID from Actual Settings → Advanced. An encrypted budget also needs its
separate encryption password. The helper sets `MCP_READ_ONLY=true`, toolsets `chat,analysis`, and
adds month enumeration and schedules reads. It keeps its local budget cache beneath
`${XDG_DATA_HOME:-~/.local/share}/opencode-assistant/actualbudget/`, outside project directories.
The official API downloads a local copy for queries; server health alone does not prove access.

AFFiNE defaults to `https://ae.shupi.ushira.com`, which requires tailnet connectivity. Supply the
self-hosted email/password login and optionally a default workspace ID from the workspace URL. The
connector uses the `core` profile with account administration, destructive operations, sharing,
database-table tools and selected unnecessary mutations disabled. Credentials for AFFiNE's built-in
MCP are a different authentication scheme and do not work here. Client and WebSocket versions match
the pinned AFFiNE server, 0.27.4.

## Gmail

The remote `google` MCP is `https://gmcp.shupi.ushira.com/mcp`, reached through the tailnet. It
reuses the Google Workspace MCP deployed on shupi, with no additional local connector package or
password in `opencode-assistant`. Deploy the Google MCP callback change and activate the local
harness before authorizing OpenCode:

```sh
opencode mcp auth google
```

Complete the browser flow as `ushiradineth@gmail.com`. OpenCode's callback is
`http://127.0.0.1:19876/mcp/oauth/callback`; the server allowlist also retains the existing app's
`http://127.0.0.1:60488/auth/google/callback`. Do not copy another client's tokens, alter OAuth
secrets or extract browser sessions. OpenCode manages its own credentials under its local data
directory in `mcp-auth.json`; keep them out of chat, Git and setup logs.

OpenCode requests base identity scopes and `https://www.googleapis.com/auth/gmail.readonly`. Its
`X-Workspace-MCP-Profile: gmail-readonly` header selects a tailnet-protected route with the matching
OAuth scope hint. This is needed because the pinned OpenCode/MCP SDK otherwise takes the shared
server's broad scope advertisement in preference to `oauth.scope`. The normal route, Google OAuth
client credentials and other clients' permissions are unchanged.

The shared server supports broader operations for other clients; the assistant is restricted by an
explicit OpenCode allowlist to seven Gmail read tools. Other Google tools and future additions
remain denied, including sends, saved drafts and mailbox mutations. Existing Google grants may be
broader than this client's requested scope, so the tool allowlist remains necessary.

`opencode mcp debug google` diagnoses discovery and OAuth failures. A denied redirect needs the
callback deployment; a reachable server is not an authenticated mailbox. Authorize in the browser,
then use `/assistant` for a bounded search and a relevant message read. Check that the authorized
account matches the expected one without printing tokens or copying mailbox contents into logs.
Attachment downloads need a supported reader before claiming their contents were inspected.

## Verify the requested sources

After activation, credential setup and restarting OpenCode:

1. `opencode mcp list` checks the two local transports and the remote Google connection.
2. In `/assistant`, request an Actual Budget context and a bounded harmless read. Confirm the
   intended budget and data coverage without copying its sensitive contents into setup logs.
3. Request the selected AFFiNE workspace and read a specified existing note. This proves a read, not
   a write. Verify writeback only when a concrete note change has been requested, then reread that
   note. Do not create test transactions or unsolicited notes to prove a connection.
4. For Gmail, complete OAuth and search/read only the relevant messages. No mail sends, saved drafts
   or label changes are part of setup.

Report each layer separately: configured, transport registered, authenticated, selected
budget/workspace/mailbox accessible, and the requested read/write verified. If credentials are
absent, give the relevant setup command and continue work that does not depend on that service.
