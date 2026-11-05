# Sources and local scope

This is a local OpenCode skill, not a wholesale import of a finance or accounting persona. Health
integrations and jurisdiction-specific tax rules are intentionally outside this setup.

The two community MCP connectors are pinned in `lib/opencode-assistant/package.json` and its
integrity-locked dependency file:

- [Actual MCP Server 0.25.1](https://github.com/agigante80/actual-mcp-server): local stdio
  transport, official `@actual-app/api`, server-enforced read-only mode and selected toolsets.
- [AFFiNE MCP Server 3.10.2](https://github.com/DAWNCR0W/affine-mcp-server): self-hosted
  authentication, core authoring profile and document revision checks. Its GraphQL and realtime
  credentials are separate from AFFiNE's native MCP credentials.

Both connectors are MIT-licensed; their npm packages retain upstream license files. These links are
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
