---
description: Generate repo-specific AGENTS.md guidance files
agent: builder
---

Create or update repository `AGENTS.md` files from actual project context.

Args: `$ARGUMENTS`

GPT-5.5 intent: produce a practical, evidence-backed operating guide that future agents can follow
safely.

Success criteria:

- Commands, testing, structure, style, git workflow, and boundaries are covered.
- Commands are sourced from repo evidence, not invented.
- Uncertainty is marked with TODO and `confidence: low`.
- Nested guides are created only where subprojects have distinct stacks or rules.

Workflow:

1. Start with scoped shell discovery using `ls` and `rg` to locate manifests, CI workflows, and
   docs.
2. Use `git status`, `git diff`, `git log`, and `git show` when git context is needed.
3. Use targeted file reads and avoid broad scans unless needed.
4. Read and follow `~/.config/opencode/prompts/init.md`.
5. Generate concrete guidance for commands, testing, structure, style, git workflow, and boundaries.
6. For monorepos, generate nested `AGENTS.md` files only where stacks differ.

Output:

- Updated `AGENTS.md` files with concise and actionable instructions.
- Verification checklist with exact commands.

Stop rules:

- Stop if authoritative commands cannot be found and label the gap.
- Stop and ask one focused question if repository purpose cannot be inferred safely.
- Do not invent CI or deploy behavior.
