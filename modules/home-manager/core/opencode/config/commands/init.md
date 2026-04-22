---
description: Generate repo-specific AGENTS.md guidance files
agent: builder
---

Create or update repository `AGENTS.md` files from actual project context.

Args: `$ARGUMENTS`

Workflow:

1. Start with scoped shell discovery (`ls`, `rg`) to locate manifests, CI workflows, and docs.
2. Use `git status`, `git diff`, `git log`, and `git show` when git context is needed.
3. Use targeted file reads and avoid broad scans unless needed.
4. Read and follow `~/.config/opencode/prompts/init.md`.
5. Generate concrete guidance for commands, testing, structure, style, git workflow, and boundaries.
6. For monorepos, generate nested `AGENTS.md` files where stacks differ.
7. Mark uncertain sections with TODO and `confidence: low`.

Output:

- Updated `AGENTS.md` files with concise and actionable instructions.
