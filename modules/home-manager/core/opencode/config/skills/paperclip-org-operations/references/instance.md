# Shu Paperclip instance

Last reviewed: 2026-10-13. Treat this as a map, not a substitute for live discovery. Read current
Nix configuration and approved agent grants before acting; a configured capability is not task
authority.

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

Container build assets live under `containers/`, outside the auto-imported host tree. Directories
under `hosts/shupi` are treated as Nix modules and need `default.nix`. For a derived private image,
verify registry publication and digest pull access as the deployment identity, not just availability
in a developer's Docker cache. Root Docker authentication and credential reuse require explicit
approval; a mode-600 login file is private but is not encrypted storage.

## CLI maintenance

Paperclip's deployed CLI supports authenticated operator maintenance through the existing
`ssh shupi` route. On 2026-10-13, the container CLI's stored board login successfully read the SHU
identity, agents, managed instructions and company skills. This is operator access, not an agent
connection or proof that every mutation is authorized.

Use the deployed CLI and its existing context; do not install another copy or copy credentials into
arguments, logs, tasks or skill files. Inspect current command help and the live OpenAPI before
choosing a command or payload. The verified non-interactive entrypoint is:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=8 shupi \
  'docker exec --user node paperclip node cli/node_modules/tsx/dist/cli.mjs cli/src/index.ts --help'
```

Verify the current identity with `whoami --api-base http://127.0.0.1:3100 --json`; select the
authorized company explicitly with `--company-id` for company-scoped commands. Relevant maintenance
reads are `agent list`, `agent skills`, `agent instructions-file:get`, `skills list`, `skills file`,
`skill get` and `openapi`. Limit retained identity/configuration output to the evidence needed for
the task.

- Run unattended commands without a TTY, with bounded timeouts and structured `--json` output. A
  `401` is an authentication blocker, not permission to mint a token. A human can use the CLI's
  interactive `connect --persona board` flow in their own terminal after approving operator access;
  then repeat the non-mutating identity check. Never run that login flow automatically.
- For content-bearing arguments, use the direct Node/tsx entrypoint above, an installed standalone
  `paperclipai` binary, or the CLI's documented stdin/file input. Do not use `pnpm paperclipai` for
  issue text, Markdown or JSON payloads: its package-script shell can reinterpret the content. Do
  not interpolate untrusted content into the SSH command; keep remote argv fixed and transfer data
  on stdin when supported.
- Preview mutations and use only the operations explicitly approved by the user. Re-fetch affected
  state afterward. For additive skill assignment use `mode: "add"`; explicit version pins require
  the documented sync API payload when CLI flags cannot express them. Never use replace-all as a
  shortcut or claim configuration readback proves runtime consumption.
- Native agents retain their advertised semantic tools and run-scoped identity. Do not reuse an
  operator's stored board credentials to bypass an agent's denied route or role boundary. CLI
  availability does not authorize agent runs, deployment, hiring, secret access or broader grants.

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
- `codexPermissionMode: "never"` means never ask for command approval; it does not override
  Paperclip governance or task scope. A null per-agent environment inherits the instance default, so
  inspect that default before diagnosing an unassigned environment.
- `enableNativeRunner` being enabled does not make an execution environment eligible for native
  runs.
- The `shu · ssh` environment has neither runner WebSocket ingress nor an explicit runner public
  URL, so it must not be selected as a native execution environment. Agents run locally and use
  `ssh shu` when work requires `~/Code`, the live Obsidian vault, or Shu-specific tools. Vault
  filesystem operations must run on `shu`, not against the Linux worker's local `/Users` path;
  follow the vault branch in `service-access.md`.
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

Codex's bubblewrap prerequisite is supplied by a static Nix binary mounted read-only at
`/usr/local/bin/bwrap` in the Paperclip container. Read `hosts/shupi/services/paperclip.nix` for the
definition. Verify it as the provider's runtime user, not on the Mac host. The basic read-only bind
and fresh provider startup passed; a stricter PID/proc namespace test was denied. Do not claim full
namespace readiness or relax container privileges from the prerequisite warning alone.

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

- Service configuration: `hosts/shupi/services/google-mcp.nix`; maintained image recipe and source
  patch: `containers/google-mcp/`. Discover the deployed image and limits from those sources.
- Current self-hosted MCP endpoint: `https://google-mcp.shupi.ushira.com/mcp`
- Health endpoint: `https://google-mcp.shupi.ushira.com/health`
- Transport: streamable HTTP
- The server is configured for Gmail, Calendar, Drive, Docs and Sheets. OAuth consent, agent/action
  grants and the accepted task scope still determine which operations are authorized.
- Intended identity: the user's personal Google account.
- Secret source: encrypted Nix secret mounted read-only; never read or copy its contents.
- The MCP is reachable from Paperclip's container and protected by the tailnet/Docker source policy.
- Approved Drive imports and Gmail archive verification were proven on SHU-30. This does not prove
  sending, deletion, calendar edits or every other service operation. Use only `Google MCP`, not a
  built-in connector fallback.
- Account-bound file handles keep transfer bytes server-side. The current source sets stateful HTTP
  mode, `HOME=/tmp`, a 16 MiB file cap and 64 MB tmpfs, while retaining a read-only root and
  disabled arbitrary local-file access. Handles expire after one hour or restart. Follow
  `service-access.md` for transfer and gateway diagnosis; do not change these controls to repair one
  attachment.

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
