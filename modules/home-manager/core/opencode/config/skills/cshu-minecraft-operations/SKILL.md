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
- Informational questions may be answered in the current lane without contacting either endpoint.
- Live server or client commands require explicit diagnostic intent in a user-invoked `sudo`
  session. From any other lane, stop and ask the user to start or switch to `sudo`; never invoke
  `sudo` through `task`.
- In `sudo`, read-only diagnosis is preauthorized after that explicit intent. Keep commands bounded,
  non-interactive, and secret-safe.
- Immediately before every local or remote mutation, obtain confirmation for the exact action,
  target, and arguments. A file edit, upload, mod/config change, restart, stop/start, restore,
  deletion, retry, changed argument, or changed target is a separate mutation and needs new
  confirmation.
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
6. If a fix is requested, stop at the mutation boundary and ask for the exact next action only.

## Near misses

Do not use this skill for generic Minecraft gameplay, unrelated mod development, general Modrinth
use, or non-Minecraft work on `shuwin` unless the user also identifies the cshu environment.

## Completion criteria

- Dynamic facts used in the response were revalidated or clearly labeled historical/unknown.
- Every live command ran inside user-invoked `sudo`. Read-only commands followed explicit diagnostic
  intent, and each mutation has its own recorded immediately preceding confirmation.
- The final report identifies evidence source, likely fault domain, remaining uncertainty, and the
  next bounded action.

## Stop conditions

Stop and ask one focused question when the access route, target, requested authority, or rollback
path is unknown. Do not infer access from host names, use automated backup credentials as operator
access, or continue from old chat consent.
