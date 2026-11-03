# Actual Budget and AFFiNE connections

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

After activation, credential setup and restarting OpenCode:

1. `opencode mcp list` checks whether both local transports register.
2. In `/assistant`, request an Actual Budget context and a bounded harmless read. Confirm the
   intended budget and data coverage without copying its sensitive contents into setup logs.
3. Request the selected AFFiNE workspace and read a specified existing note. This proves a read, not
   a write. Verify writeback only when a concrete note change has been requested, then reread that
   note. Do not create test transactions or unsolicited notes to prove a connection.

Report each layer separately: configured, transport registered, authenticated, selected
budget/workspace accessible, and the requested read/write verified. If credentials are absent, give
the relevant setup command and continue work that does not depend on that service.
