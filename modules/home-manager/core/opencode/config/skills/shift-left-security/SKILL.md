---
name: shift-left-security
description:
  Use when implementing or reviewing code with local SAST, staged security hooks, SQL-injection
  prevention, advisory security candidates, or an explicitly requested disposable local DAST run.
---

# Shift-left security

## Core rule

Catch high-confidence defects locally before readiness while keeping broader scanner output advisory
until source evidence verifies it.

## Route by need

- Local SAST, staged-file enforcement, or Fallow candidates: read `references/local-sast.md`.
- SQL construction or database-query review: read `references/sql-injection.md`.
- A user-requested local dynamic scan: read `references/local-dast.md` before any container or
  network action.

## Workflow

1. Read the repository guide and existing local security configuration.
2. Use reviewed local rules owned by the repository or the managed central baseline. Prefer
   `semgrep-local` for confined offline scans; select any private profile explicitly. Read
   `references/local-sast.md` for scope and failure handling. Run the smallest applicable check
   after relevant edits and again before readiness.
3. Block only findings from locally tested high-confidence rules. Treat Fallow and broader scanner
   results as candidates, then use `security-audit` guidance to verify source, data flow,
   reachability, and impact before changing code.
4. Preserve repository-native tests, type checks, lint, and review gates; scanner success does not
   replace them.
5. Report the command, scope, findings, verification status, and anything still needing validation.

## Boundaries

- Do not fetch remote Semgrep configurations, log in, enable telemetry, or send source to a cloud
  service.
- Keep personal scanner rules, profiles, reports and hooks out of work repositories. Missing central
  tooling or OS confinement is a reported blocker, not permission to install target tooling or run
  an unconstrained fallback.
- Do not add CI, CodeQL, Sonar, editor integration, MCP, Fallow hooks, or automatic hook
  installation unless separately requested and planned.
- Never run active or authenticated DAST automatically. Never scan production, staging, shared
  services, shupi, or an arbitrary URL.
- Dynamic checks require explicit user intent and a disposable local target. Otherwise perform only
  static structure validation and report the dynamic result as `needs_validation`.
