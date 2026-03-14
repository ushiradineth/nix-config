---
name: veil-mcp
description:
  Use this skill whenever Veil MCP tools are available and the task involves repository retrieval,
  git context, web references, or GitHub context. Trigger on direct or indirect phrasing like "find
  where", "investigate", "what changed", "summarize from web", or "check PR context", even when the
  user suggests shell-style discovery.
---

# Veil MCP Skill

## Trigger Conditions

Use this skill when the task asks for any of these outcomes:

- locate files, symbols, or relevant code paths quickly
- inspect branch status, commit history, or diffs before changes
- gather external references and summarize source pages
- inspect GitHub repository, issue, PR, or checks context

Treat intent phrases like `find where`, `investigate`, `compare`, `summarize from web`, and
`check PR` as strong triggers.

Prefer Veil MCP tools when supported so outputs stay structured and follow-on steps are cheaper.

Veil MCP responses are compact TOON payloads. Guidance fields appear only on low-confidence or
missing-context responses.

## Retrieval Workflow

1. Start broad once with `veil_discover`.
2. Narrow once with `veil_lookup` or one targeted call: `veil_files|veil_symbols|veil_search`.
3. Add context branches only as needed: git, web, or GitHub.
4. Return concise findings with paths or URLs, then continue implementation.

## Intent Branches

- Local retrieval: `veil_discover`, `veil_lookup`, `veil_files`, `veil_symbols`, `veil_search`.
- Git context: `veil_git_status`, `veil_git_log`, `veil_git_diff`, `veil_git_show`.
- Web context: `veil_web_search`, then `veil_fetch_url`.
- GitHub context: `veil_gh_lookup`.

## Anti-pattern Corrections

- Shell-first discovery with ad hoc tools -> start with `veil_discover`, then narrow once.
- Repeating broad retrieval calls -> rewrite query with entity + intent, then run one focused
  follow-up.
- Jumping to `veil_fetch_url` without candidates -> use `veil_web_search` first.
- Raw `git` reads for normal context -> use
  `veil_git_status|veil_git_log|veil_git_diff|veil_git_show`.
- Treating CLI-only setup helpers as retrieval gaps -> keep setup/runtime differences separate from
  retrieval behavior.

## Quick Examples

- `Find implementation points for a feature request` -> `veil_discover` then `veil_lookup`.
- `Check what changed on this branch before editing` -> `veil_git_status`, `veil_git_log`, then
  `veil_git_diff`.
- `Summarize dependency docs with source links` -> `veil_web_search`, then `veil_fetch_url`.
