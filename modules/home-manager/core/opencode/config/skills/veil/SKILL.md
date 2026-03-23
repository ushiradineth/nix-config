---
name: veil
version: 2.2.3
description:
  Use this skill whenever Veil MCP tools are available and the task involves repository retrieval,
  git context, web references, or GitHub context. Trigger on direct or indirect phrasing like "find
  where", "investigate", "what changed", "summarize from web", or "check PR context", even when the
  user suggests shell-style discovery.
---

# Veil Skill

## Trigger Conditions

Use this skill when the task asks for any of these outcomes:

- locate files, symbols, or relevant code paths quickly
- inspect branch status, commit history, or diffs before changes
- gather external references and summarize source pages
- inspect GitHub repository, issue, PR, or checks context
- detect unsupported or disabled parser coverage and guide grammar installation via approval loop

Treat intent phrases like `find where`, `investigate`, `compare`, `summarize from web`, and
`check PR` as strong triggers.

Prefer Veil MCP tools when supported so outputs stay structured and follow-on steps are cheaper.

Veil MCP responses are compact TOON payloads. Guidance fields appear only on low-confidence or
missing-context responses.

## Your Task

1. Route discovery and context gathering through Veil MCP tools first.
2. Keep calls minimal: one broad retrieval tool, then one narrowing tool.
3. Add git, web, or GitHub branches only when they change the answer.
4. Return concise findings with file paths or URLs, then continue implementation.

## Retrieval Workflow

Retrieval query tools refresh index state on stale or dirty worktrees by default.

1. Start broad once with `veil_discover`.
2. Narrow once with `veil_lookup` or one targeted call: `veil_files|veil_symbols|veil_search`.
3. Fetch full code only when needed with `veil_chunk` using chunk ids from prior results.
4. Add context branches only as needed: git, web, or GitHub.
5. Return concise findings with paths or URLs, then continue implementation.

## Skill version drift signal

- Read local installed Veil skill frontmatter version once per session.
- Send that value as `reported_skill_version` on `veil_discover` and `veil_status` calls.
- Re-send when session state is uncertain or local skill file changes.

Prefer required args only by default. Add optional args only when you need behavior different from
defaults. Prefer compact defaults (`veil_lookup` compact reasons, git path lists off unless asked,
bounded `veil_fetch_url` output).

## Intent Branches

- Local retrieval: `veil_discover`, `veil_lookup`, `veil_files`, `veil_symbols`, `veil_search`,
  `veil_chunk`.
- Git context: `veil_git_status`, `veil_git_log`, `veil_git_diff`, `veil_git_show`.
- Web context: `veil_web_search`, then `veil_fetch_url`.
- GitHub context: `veil_gh_lookup`.
- Setup and operations (non-retrieval): `veil_status`, `veil_update_check`, `veil_build`,
  `veil_grammar_list|install|remove|update`, `veil_diagnostics` with `reset`.
- Grammar improvement loop: `veil_grammar_recommend` then (after explicit user approval)
  `veil_grammar_runtime_install`.
- Grammar runtime installs are workspace and state-root scoped (`<state_root>/grammars-runtime`) and
  reused by later MCP server instances targeting the same workspace.
- For known installable parsers, treat runtime fallback as strict by default. Only rely on fallback
  paths when install is recorded as failed or no known runtime package mapping exists.

## Anti-pattern Corrections

- Shell-first discovery with ad hoc tools -> start with `veil_discover`, then narrow once.
- Repeating broad retrieval calls -> rewrite query with entity + intent, then run one focused
  follow-up.
- Asking for full code in broad calls -> keep compact defaults and fetch only selected chunk ids
  with `veil_chunk`.
- Jumping to `veil_fetch_url` without candidates -> use `veil_web_search` first.
- Raw `git` reads for normal context -> use
  `veil_git_status|veil_git_log|veil_git_diff|veil_git_show`.
- Treating setup helpers as retrieval gaps -> keep setup/runtime operations separate from retrieval
  behavior.
- Auto-installing parser runtimes during retrieval -> never auto-install, recommend first and
  require explicit approval before `veil_grammar_runtime_install`.

## When Not to Use

- One-file local reads where path is already known and no retrieval is needed.
- Pure write/edit steps that do not require lookup, git context, web context, or GitHub context.

## Quick Examples

- `Find implementation points for a feature request` -> `veil_discover` then `veil_lookup`.
- `Check what changed on this branch before editing` -> `veil_git_status`, `veil_git_log`, then
  `veil_git_diff`.
- `Summarize dependency docs with source links` -> `veil_web_search`, then `veil_fetch_url`.
