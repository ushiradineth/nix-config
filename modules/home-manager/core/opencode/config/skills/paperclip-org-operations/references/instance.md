# Shu Paperclip instance

Last reviewed: 2026-10-09. Treat this as a map, not a substitute for live discovery.

## Deployment

- Public URL: `https://paperclip.shupi.ushira.com`
- Host: `shupi`
- Company URL key: `SHU`
- Company ID: `f530959e-fd96-4eb2-be2e-7cd728281c21`
- Deployment mode: authenticated
- Exposure: private, tailnet-only through Traefik
- Container source: `hosts/shupi/services/paperclip.nix`
- Persistent data: `/srv/paperclip` on `shupi`, mounted at `/paperclip`
- Local controller API inside the container: `http://127.0.0.1:3100`
- Backup: hourly logical Paperclip database backup plus host backup policy
- Official image currently pinned in Nix. Read the Nix file for the live tag and digest instead of
  copying the value from this reference.

The Nix repository is the infrastructure source of truth. Paperclip's database is the organization
state source of truth. Do not edit database rows or managed files to make routine control-plane
changes.

## Known agents

- Dot: `bcf34395-b047-4777-a166-42e003d9831e`
- Summarizer: `26a66408-6a20-4396-b2aa-ac753b9c0d54`
- Other specialists, including the Tax Specialist, must be discovered live rather than identified by
  a cached UUID.

Dot is the user's personal manager and preferred intake point. Summarizer is a read-and-report
built-in agent. Do not broaden Summarizer's authority to compensate for another role.

## Models and Codex authentication

- Paperclip's company-managed Codex home is under
  `/paperclip/instances/default/companies/<company-id>/codex-home`.
- ChatGPT device authorization is the current authentication path.
- `codex-mini-latest` is not compatible with this ChatGPT account.
- `gpt-6-luna` is the economical default for bounded summaries and lightweight helpers.
- Use a stronger available model such as `gpt-6-sol` for complex planning, migration, or risky
  operational decisions when Paperclip and the account support it.
- OpenCode model aliases do not prove Paperclip/Codex compatibility. Verify with a bounded run.
- Raw provider tracing is a temporary diagnostic mode. Disable it after the fault is understood.

## Runtime and adapter limits

- On 2026-10-09, all seven current agents were migrated to local `paperclip_runner` execution with
  provider `codex`, `lifecycleMode: "per_turn"`, and `codexPermissionMode: "never"`.
- Summarizer uses `gpt-6-luna`; the other six agents use `gpt-6-sol`. Existing responsible-user
  OpenAI bindings, heartbeat policies, managed instructions, and skill selections were preserved.
- Native config intentionally excludes legacy `engine` and `command` fields. Do not add them as a
  migration workaround.
- `enableNativeRunner` being enabled does not make an execution environment eligible for native
  runs.
- The `shu · ssh` environment has neither runner WebSocket ingress nor an explicit runner public
  URL, so it must not be selected as a native execution environment. Agents run locally and use
  `ssh shu` only when work requires `~/Code` or Shu-specific tools.
- Paperclip receives a dedicated, source-restricted SSH identity through read-only mounts. OpenSSH
  discovers `shu` through `/etc/ssh/ssh_config.d/99-paperclip.conf`; this system-level config is
  required because managed GitHub runs use a run-scoped home instead of `/paperclip`.
- `PAPERCLIP_GITHUB_*` and runner network variables are controller-owned. Do not try to inject them
  through agent variables or rely on ambient container values to project `.ssh`.
- The bounded `SHU-28` pilot renamed its task with `set_task_title`, found Google MCP with
  `connections_search`, and ran `ssh shu 'printf native-ssh-ok'` successfully before the migration
  was widened.
- The pinned runner rejects semantic tool text when a sensitive noun followed by whitespace looks
  like a shell-style credential pair, even if the text only describes setup. A one-option question
  is also invalid. Follow the generic detector-safe confirmation pattern in `service-access.md` for
  every missing-value request.

- Before a future adapter or transport migration, keep a rollback revision and prove one real
  bounded run through the same agent-visible path before widening the change.

## Skills

- `summarize-status` is the bundled operating skill for Summarizer.
- `paperclip-org-operations` is the repository-managed skill for instance, agent, access, Dot, and
  organization operations.
- Repository source: `modules/home-manager/core/opencode/config/skills/paperclip-org-operations/`

Edit the repository source first, review the diff, validate it, then publish a new Paperclip skill
version. Do not let the installed copy become an undocumented fork.

## Google services

- Current self-hosted MCP endpoint: `https://google-mcp.shupi.ushira.com/mcp`
- Health endpoint: `https://google-mcp.shupi.ushira.com/health`
- Transport: streamable HTTP
- Current data scopes: Gmail read-only, Drive read-only, Calendar read-only, plus the identity
  scopes required by OAuth.
- Intended identity: the user's personal Google account.
- Secret source: encrypted Nix secret mounted read-only; never read or copy its contents.
- The MCP is reachable from Paperclip's container and protected by the tailnet/Docker source policy.
- On 2026-10-09, native `connections_search("google")` reported Google MCP ready. Google Drive and
  Gmail organization connectors remained drafts; this did not prove personal Drive, Gmail, or
  Calendar reads.

Paperclip's official Google connector was previously unsuitable because it required Google Workspace
Developer Preview rather than supporting a consumer Gmail account. Recheck this fact from current
official behavior before migration. Run the official connector in parallel, verify parity, and
obtain explicit approval before disabling the self-hosted MCP.

## Discovery rules

- Use the company ID from `PAPERCLIP_COMPANY_ID` during a run; compare it with this reference rather
  than blindly substituting the cached value.
- Read agents, desired skills, routines, connections, profiles, and policies through company-scoped
  APIs.
- Use Paperclip's OpenAPI output or bundled CLI help for current route and payload shapes.
- Do not place bearer tokens, OAuth codes, API keys, cookies, or decrypted secret values in tickets,
  comments, traces, or this reference.
