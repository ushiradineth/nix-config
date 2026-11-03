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
