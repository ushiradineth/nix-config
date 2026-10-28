---
name: cshu-minecraft-operations
description:
  Use when a prompt names cshu, cshuu.modrinth.gg, or a Minecraft issue on shuwin and needs
  server/client context, diagnosis, or operations; do not use for generic Minecraft, Modrinth, or
  unrelated shuwin tasks.
---

# cshu Minecraft operations

## Authority contract

- Skill activation supplies context. It does not grant permission to run commands or change state.
- Informational questions may be answered in the current session without contacting either endpoint.
- Live server or client commands require an explicit diagnostic or operational request for the
  target. Scoped read-only diagnosis then proceeds in the current session. Keep commands bounded,
  non-interactive, and secret-safe.
- A live mutation needs authorization covering its action and target. Preserve existing approval;
  ask before a new restart, restore, deletion or access change outside that scope. Repository
  deployment and secret-wiring boundaries still apply.
- Never read, decrypt, print, copy, or embed credential contents. Redact secrets from evidence.

## Workflow

1. Classify the request as informational, read-only diagnosis, or mutation.
2. Read [environment and access](references/environment-and-access.md) before stating endpoint,
   path, profile, version, backup, or access facts.
3. For an incident, read [the incident playbook](references/incident-playbook.md) and apply
   `diagnose`.
4. Gather the smallest evidence set that can distinguish server, client, network, loader, mod-set,
   and configuration causes.
5. Report observations separately from hypotheses. Do not turn noisy warnings into a root cause
   without symptom-linked evidence.
6. If a fix is requested, perform the authorized change and verify the consumer-visible result. Ask
   only at a mutation boundary whose authority is still missing.

## Near misses

Do not use this skill for generic Minecraft gameplay, unrelated mod development, general Modrinth
use, or non-Minecraft work on `shuwin` unless the user also identifies the cshu environment.

## Completion criteria

- Dynamic facts used in the response were revalidated or clearly labeled historical/unknown.
- Live commands stayed within the requested target and authority. Mutations have explicit scope;
  successful command output is followed by service or client verification.
- The final report identifies evidence source, likely fault domain, remaining uncertainty, and the
  next bounded action.

## Stop conditions

Stop and ask one focused question when the access route, target, requested authority, or rollback
path is unknown. Do not infer access from host names, use automated backup credentials as operator
access, or expand the scope of an earlier authorization.
