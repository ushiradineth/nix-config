---
name: veil
description: Route agent tasks to Veil MCP tools with a practical local-first then web workflow.
---

# Veil Skill

Use this skill when an agent should prefer Veil tools over shell-first discovery.

## Routing order

1. Local code or architecture questions:
   - Start with `discover`.
   - If results are mixed, run `lookup`.
   - Use `files`, `symbols`, or `search` for narrow follow-up.

2. Web research and docs lookup:
   - Start with `web_search`.
   - Open selected links with `fetch_url` using `format=markdown`.

3. Repository history or dirty tree context:
   - Use `git_status`, `git_log`, `git_diff`, `git_show`.

4. GitHub metadata:
   - Use `gh_lookup`.

5. Tool health and performance:
   - Use `diagnostics`.

## Rules

- Do not use shell `find` or `grep` for normal repo discovery when Veil tools fit.
- Do not use generic web fetch for page extraction when `fetch_url` exists.
- Do not skip `discover` for broad local queries.
- Prefer one precise follow-up call over many speculative calls.

## Query tips

- `discover`: user phrasing is usually enough.
- `lookup`: use specific intent phrasing, for example `where is <symbol> defined`.
- `web_search`: start short, then refine.
- `fetch_url`: set `format=markdown` and keep timeout and size bounded.

## Output expectations

- Keep responses concise.
- Include source URLs for web-derived claims.
- Clearly mark unsupported or partial results.
