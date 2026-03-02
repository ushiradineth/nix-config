---
description: Build, refresh, verify, and query the local repository index
agent: build
---

Manage repository indexing for the current workspace using MCP tools and local artifacts under
`.agents/index/*`.

Args: `$ARGUMENTS`

Modes:

- `status`: check freshness via `veil_status`
- `refresh` (default): run `veil_refresh` with `mode: changed`
- `full`: run `veil_refresh` with `mode: full`
- `search <query>`: run `veil_search`
- `symbols <query>`: run `veil_symbols`
- `files <query>`: run `veil_files`

Behavior:

1. Always call `veil_status` first.
2. If index is missing or stale, refresh it before any search call.
3. Print concise results and include exact file paths and line numbers when available.
4. If MCP is unavailable, fall back to local CLI:
   - `nix run nixpkgs#bun -- run /Users/shu/Code/veil/src/cli.ts status --workspace <cwd>`
   - `nix run nixpkgs#bun -- run /Users/shu/Code/veil/src/cli.ts refresh --workspace <cwd> --mode changed`
5. Keep output short and actionable.
