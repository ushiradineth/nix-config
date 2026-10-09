# Upstream provenance

- Repository: https://github.com/fallow-rs/fallow
- Version: `3.32.0`
- Revision: `aaaec796f5449810b9ecf82ed7e62b775d4d1ef3`
- License: MIT, copied in `LICENSE`
- Upstream source: `npm/fallow/skills/fallow/SKILL.md`
- Upstream license SHA-256: `b291c8e1e0cac7a3646cd5539d7c728f2ce425678eedd1afeeea3c35838c29a9`

This OpenCode adapter is derived from upstream behavior rather than maintained byte-for-byte. It is
intentionally narrower: local CLI analysis only, with hooks, MCP, remote configuration, telemetry,
and automatic project setup excluded.

## Update procedure

1. Fetch and review the intended upstream revision.
2. Verify `npm/fallow/package.json`, the root `LICENSE`, CLI exit semantics, and telemetry controls.
3. Update the managed package pin, this provenance record, and the adapter together.
4. Re-run package smoke, activation evaluation, skill discovery, formatting, flake checks, and the
   non-switching host build.
