# Sources and local scope

This is a local OpenCode skill, not a wholesale import of a finance or accounting persona. Health
integrations and jurisdiction-specific tax rules are intentionally outside this setup.

Obsidian notes use the local OpenCode custom tools in `config/tools/obsidian.ts`, without extra
runtime dependencies. They enforce the vault root, Markdown paths and stale-read checks, and expose
no deletion or rename action. The pinned OpenCode 1.18.35 checks built-in edits against
project-relative paths, so an absolute vault allowlist does not work across projects; the local
tools enforce this boundary independently. No notebook MCP package or API credential is required.
The self-hosted Selfsync service in `hosts/shupi/services/selfsync/` and its Obsidian plugin handle
replication separately; they are not an agent transport. Recheck native file permissions and
readback when the vault location or OpenCode version changes.

The community Actual Budget MCP connector is pinned in
`modules/home-manager/core/opencode/assistant/connectors/package.json` and its integrity-locked
dependency file:

- [Actual MCP Server 0.25.1](https://github.com/agigante80/actual-mcp-server): local stdio
  transport, official `@actual-app/api`, server-enforced read-only mode and selected toolsets. The
  connector is MIT-licensed; its npm package retains upstream license files. This link is
  provenance, not instructions to install a moving main branch. Update the package lock and exercise
  native tool discovery, permissions and representative service reads when upgrading.

Gmail uses the existing MIT-licensed
[Google Workspace MCP](https://github.com/taylorwilsdon/google_workspace_mcp/tree/2e9e9e785d30abaf89cf181c548d172b09ed0150),
whose pinned image and local patches are managed by `hosts/shupi/services/google-mcp.nix` and
`containers/google-mcp/`. OpenCode uses its native remote MCP/OAuth support; no Google connector is
added to the npm lock. The shared server supports other Google services and write operations, but
the personal assistant receives only an explicit set of Gmail reads and requests Gmail read-only
OAuth access. Recheck the advertised schemas, native permission filtering and OAuth scopes when
upgrading either OpenCode or the server. The server's profile-specific Traefik route narrows the
OAuth challenge for this client: pinned OpenCode otherwise replaces the configured scope with the
broader server advertisement. The route preserves the existing tailnet restriction and shared
endpoint; it does not add a connector process or change other clients' permissions.
