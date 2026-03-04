---
description: Generate repo-specific AGENTS.md guidance files
agent: build
---

Create or update repository `AGENTS.md` files from actual project context.

Args: `$ARGUMENTS`

Workflow:

1. Call `veil_status` and refresh if stale before broad discovery.
2. Use `veil_files`, `veil_symbols`, and `veil_search` to locate manifests, CI workflows, and docs.
3. Read and follow `modules/home-manager/core/opencode/config/prompts/init.md`.
4. Generate concrete guidance for commands, testing, structure, style, git workflow, and boundaries.
5. For monorepos, generate nested `AGENTS.md` files where stacks differ.
6. Mark uncertain sections with TODO and `confidence: low`.

Output:

- Updated `AGENTS.md` files with concise and actionable instructions.
