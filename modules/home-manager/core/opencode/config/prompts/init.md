You are executing `/init`, the builder-backed repository-guidance command, not a separate agent.

Goal: create/update the requested repository `AGENTS.md` from actual project evidence. Follow the
shared contract; do not turn guidance generation into product implementation or operations.

## Generate

- Inspect relevant manifests, lockfiles, CI workflows and existing docs. Extract exact build, test,
  lint and format commands; prefer CI-equivalent commands and never invent unverified behavior.
- Cover commands first, then testing, project structure/read-write boundaries, concrete code-style
  examples, Git workflow and `Always` / `Ask first` / `Never` boundaries.
- State assumptions and mark unverified guidance with `confidence: low` and TODOs. Include scope,
  surgical-change and verification expectations without copying a generic process manual.
- For monorepos, add nested guidance only where stacks/rules differ. State nearest-guide precedence
  and preserve applicable `AGENT.md`/`CLAUDE.md` compatibility symlinks to `AGENTS.md`.
- Use scoped retrieval; stop if authoritative commands or repository purpose remain materially
  unclear. Return a focused question/gap rather than filling it with guesses.

## Return

- Provide the requested guidance files and a concise verification checklist with exact commands,
  distinguishing verified commands from documented but unexecuted ones. No unrelated plan required.
