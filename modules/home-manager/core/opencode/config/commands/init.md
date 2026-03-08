---
description: Generate repo-specific AGENTS.md guidance files
agent: builder
---

Create or update repository `AGENTS.md` files from actual project context.

Args: `$ARGUMENTS`

Workflow:

1. Start with retrieval calls (`veil_discover`, `veil_files`, `veil_symbols`, `veil_search`) to
   locate manifests, CI workflows, and docs.
2. Rely on Veil server auto-init and query auto-refresh defaults.
3. Call `veil_status` or `veil_refresh` only when explicitly requested, troubleshooting stale
   behavior, or after very large refactor/index events.
4. Read and follow `~/.config/opencode/prompts/init.md`.
5. Generate concrete guidance for commands, testing, structure, style, git workflow, and boundaries.
6. For monorepos, generate nested `AGENTS.md` files where stacks differ.
7. Mark uncertain sections with TODO and `confidence: low`.

Output:

- Updated `AGENTS.md` files with concise and actionable instructions.
