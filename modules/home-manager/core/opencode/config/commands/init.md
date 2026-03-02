---
description: Generate repo-specific AGENTS.md guidance files
agent: build
---

Create or update repository `AGENTS.md` files from actual project context.

Args: `$ARGUMENTS`

Workflow:

1. Read and follow `modules/home-manager/core/opencode/config/prompts/init.md`.
2. Inspect manifests, lockfiles, CI workflows, and existing docs before writing.
3. Generate concrete guidance for commands, testing, structure, style, git workflow, and boundaries.
4. For monorepos, generate nested `AGENTS.md` files where stacks differ.
5. Mark uncertain sections with TODO and `confidence: low`.

Output:

- Updated `AGENTS.md` files with concise and actionable instructions.
