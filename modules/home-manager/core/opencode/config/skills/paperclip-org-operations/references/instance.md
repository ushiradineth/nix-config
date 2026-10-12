# Shu Paperclip instance

Last reviewed: 2026-10-12. Treat this as a map, not a substitute for live discovery. Google access
notes below retain their earlier scope context; discover current approved grants before acting.

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
- Summerizer (built-in key `summarizer`): `26a66408-6a20-4396-b2aa-ac753b9c0d54`
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
- The built-in summary agent uses `gpt-6-luna`; the other six agents use `gpt-6-sol`. On 2026-10-12,
  its missing managed OpenAI selection was restored as `responsible_user`, provider `openai`, method
  `subscription`, using the existing default account without a model change.
- Summary-slot writes are restricted to the registered built-in agent. An ordinary agent copy does
  not gain that authority from copied instructions. Use a routine owned by a real active company
  member; built-in routine owner `built-in-bundles` is not a valid responsible user. The user-owned
  manual routine completed SHU-48 as a no-op: no generated baseline qualified.
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

- Shared capability integration was verified on 2026-10-12: native Dot loaded pinned
  `engineering-quality`, `browser-workflow`, and `verification-before-completion`, executed the Mac
  helper through SSH, retrieved/viewed PNG bytes and completed the paired disposable UI trial. This
  is bounded evaluation evidence, not a guarantee for every future coding task.
- Other specialists observed the assigned skill names but reported unreadable advertised source
  aliases. Their source-only summaries do not prove full procedure consumption. Treat unreadable
  sources as a delivery limitation, not permission to scan private paths or weaken filesystem rules.
- The remaining reviewed techniques are company-catalog packages selected by relevant task. Keep
  default bindings small: selected bundle roots can exceed the runner's 4,096-byte per-argument
  launch bound. See `capability-sync.md`; never bypass the guard or change an adapter to force fit.
- The pre-existing operational skill/version is intentionally preserved during this integration;
  repository maintainer references do not imply that its old Paperclip pin was silently upgraded.

- `summarize-status` is the bundled operating skill for Summarizer.
- `paperclip-org-operations` is the repository-managed skill for instance, agent, access, Dot, and
  organization operations.
- Repository source: `modules/home-manager/core/opencode/config/skills/paperclip-org-operations/`

Edit the repository source first, review the diff, validate it, then publish a new Paperclip skill
version. Do not let the installed copy become an undocumented fork.

## Browser on shu

- Installed entrypoint: `/run/current-system/sw/bin/agent-browser-task` on `shu`; native provider
  execution stays on `shupi`. Use the existing source-restricted SSH identity, no CDP/MCP exposure.
- Fresh headless, task-owned namespaces use a clean private HOME and short private socket directory;
  the supported CLI version is `0.38.1`. Health does not prove navigation/rendering by itself.
- Initial authority is public-read or explicitly approved disposable-local UI work. Personal
  profiles, saved authentication, external submissions and broader connections need separate
  approval.
- Screenshot bytes must reach the native workspace and be verified/viewed. For deliverables, use the
  actual advertised schema and root-level basenames; nested-path registration was rejected in the UI
  trial while the same verified bytes registered with the proven seven-field contract.
- SHU-37 and SHU-38 contain browser/coding evidence and task attachments. Registration means task
  preparation, not delivery into an external chat. Existing same-user SSH is not an OS sandbox.

## Google services

- Current self-hosted MCP endpoint: `https://google-mcp.shupi.ushira.com/mcp`
- Health endpoint: `https://google-mcp.shupi.ushira.com/health`
- Transport: streamable HTTP
- Initial data scopes were Gmail, Drive and Calendar read-only, plus OAuth identity scopes. This
  historical list is not the current permission boundary; use the approved connection's live grants.
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
