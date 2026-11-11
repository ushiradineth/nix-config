# OpenCode with Seojiyu

Use OpenCode normally. The `jiyu` primary agent applies `jiyu-mode` to substantive work. Describe
the goal and a checkable result. Design, implementation and verification stay in the same session.
An obvious edit or simple question needs no workflow setup.

```text
Fix duplicate notifications after a retry. Repro first, then fix and verify.
Rewrite this cache from first principles, migrate every caller, and keep going until verified.
/attack-the-diff the current branch
/ketchup
```

## How work flows

```mermaid
flowchart LR
  A[Goal and done check] --> B[Understand and design]
  B --> C[Implement and verify]
  C --> D[Clean the diff]
  D --> E[Attack correctness]
  E --> F[Challenge structure]
  F --> G[Verify and deliver]
```

The default router reads one relevant playbook. It uses `how` and `why` to ground unfamiliar code,
`architect` for consequential shape decisions, and prototypes for questions an experiment can
answer. `arena` compares competing approaches. `swarm` covers independent slices.

Large or unfamiliar work uses `figure-it-out` to design a verifiable run. Long or unattended work
uses `show-me-your-work` to record decisions, discarded hypotheses, evidence and resume points. Its
append-only TSV helper preserves rows and escapes spreadsheet formulas.

Before delivering a substantive code change, the attack-the-diff playbook runs:

1. `deslop` removes code padding and dead weight.
2. `no-comments` checks comments with fresh eyes, preserving real rationale and constraints.
3. `interrogate` attacks correctness and verifies failure cases.
4. `thermo-nuclear-code-quality-review` challenges ownership, state, abstractions and reader load.
5. The primary fixes accepted findings and reruns affected checks.

These are distinct purposes at one completed review boundary. They do not run after every file.
Trivial edits get an inline check. Repeated passes need a material change or an unresolved finding.

## UI design with Impeccable

Jiyu automatically uses `impeccable` when the requested result involves visual or interaction
design: UI brainstorming, screens, layout, typography, UX copy, accessibility, responsiveness,
motion or interface review. Ordinary coding, backend work, architecture discussions and frontend
logic/refactoring that leaves the experience unchanged stay on their normal engineering routes.
Mixed work uses Impeccable for the UI portion and one shared integration/code-review boundary.

Describe the UI goal normally, or select a move explicitly:

```text
Brainstorm three settings layouts for frequent keyboard users. Ideas only.
Fix this dialog's narrow-screen layout while keeping its Kumo components and behavior.
/impeccable critique the onboarding flow
/impeccable shape the new workspace screen
/impeccable polish the checkout form
```

The sequence is context → shape/build → critique/audit → targeted fixes → polish, scaled to the
task. A small fix loads its relevant reference; it does not run the entire sequence. Brainstorming,
shape, critique and audit stay read-only unless implementation was also requested. A bare
`/impeccable` offers a few next moves without running them.

Operate, Read, Persuade and Experience modes distinguish an efficient tool from a reading surface,
marketing page or showcase. Existing brand rules, design tokens, component libraries and native
platform conventions remain authoritative. Missing PRODUCT.md or DESIGN.md does not block a local
refinement or authorize a redesign. `init`, `document` and `extract` are available when their
specific context/system work is useful or requested. Top-level `/init` and `/teach` retain their
engineering meanings; Impeccable's aliases are namespaced under `/impeccable`.

The design references cover layout, typeset, clarify, distill, harden, adapt, onboard, optimize,
colorize, bolder, quieter, animate, delight, overdrive and polish. Native platform guidance loads
only when applicable. Verify the actual affected render and interaction through existing browser or
native procedures; a screenshot is not a functional test.

The adaptation does not install upstream's binary detector, automatic hooks, live-picker service or
shortcut generator. Variants use existing preview tools. No background UI scan runs after ordinary
development edits. Source and local choices are recorded in
[Impeccable provenance](skills/impeccable/UPSTREAM.md).

The full detail behind all 24 upstream principles lives under
`skills/jiyu-mode/references/principles/`, indexed by `references/principles.md`. The agent reads
the applicable rule, rather than loading 24 more skill entries or reciting principle names in every
reply. Steering by a principle's name still works.

## Agents and tools

| Agent       | Responsibility                                                                                       |
| ----------- | ---------------------------------------------------------------------------------------------------- |
| `jiyu`      | Primary owner of the goal, design, implementation, integration and proof.                            |
| `sudo-jiyu` | Same prompt, instructions and model as Jiyu, with every OpenCode permission allowed.                 |
| `general`   | Bounded implementation or investigation worker.                                                      |
| `explore`   | Read-only source mapping.                                                                            |
| `reviewer`  | Read-only correctness, comment or structural review.                                                 |
| `assistant` | Personal Actual Budget analysis and AFFiNE notebook work; available directly or as a bounded worker. |

Workers cannot launch other agents. Competing writes get separate workspaces; shared review can use
the same source. The primary inspects their artifacts and verifies integration.

Select `sudo-jiyu` for Jiyu with unrestricted OpenCode tool, shell, directory, delegation and MCP
access. It shares `prompts/jiyu.md`, `AGENTS.md`, skills and instructions with `jiyu`; only its
agent-level permission changes to `"*": "allow"`. The default agent remains `jiyu`.

### Personal budgeting, Gmail and AFFiNE

Describe a spending, budget, email or personal notebook task normally. Jiyu routes it to
`assistant`, whose service tools stay out of ordinary coding agents. `/assistant <request>` selects
the role directly; a bare `/assistant` shows examples without reading accounts. The assistant
inherits the configured model and cannot run shell commands, edit project files or launch workers.

```text
/assistant Review October's personal spending. Explain transfers and missing coverage.
/assistant Find this year's receipts from my accountant and list any missing tax documents.
/assistant Find my trip plan and append these three packing items: ...
/assistant Save a monthly budget review in AFFiNE with the source period and my chosen actions.
```

The assistant also knows the local Google Drive document root:
`/Users/shu/Library/CloudStorage/GoogleDrive-ushiradineth@gmail.com/My Drive/`. Its existing file
permissions allow searching and reading tax records and other relevant personal documents there.
Source files remain read-only; requested notebook updates go to AFFiNE. A file that is unavailable
locally or unsupported by the available reader is reported explicitly.

`documents_read` supplies bounded extraction for local PDF/text/JSON files and HTTPS PDFs. It
unwraps saved JSON tool responses and runs English OCR locally on PDF pages with scant text.
Responses include page methods, empty-page flags and continuation offsets; originals stay intact. It
accepts document parameters rather than shell commands or executable code. Python, pypdf, Poppler
and Tesseract are packaged through Nix; no private document is uploaded for conversion. Encrypted
PDFs require an unlocked local copy. Other formats continue to use their existing readers.

The local AFFiNE adapter returns paged Markdown instead of duplicating blocks, plain text and
Markdown in one large response. Literal `find` seeks a section before paging; revision and document
identity accompany each excerpt. Explicit block reads preserve IDs and deltas for incremental edits.
The adapter forwards writes and their revision preconditions unchanged. Shell and arbitrary
context-mode execution remain denied for the assistant.

Gmail uses the existing Google Workspace MCP on shupi over the tailnet. Only the assistant can use
its seven mail read tools: search, message/thread reads (single or batch), attachment retrieval and
label listing. Other Google services and all mailbox changes remain denied, including sends, saved
Gmail drafts, marking read, archiving and deletion. Replies can be drafted in chat. Email results
include source message links; downloading an attachment does not prove it was read.

Actual Budget is enforced read-only, with one configured budget Sync ID and a small analysis/query
toolset. It cannot change transactions, move money, switch budgets or run bank sync. AFFiNE can
find/read notes and perform requested incremental authoring; deletion, full-note replacement,
publishing and account administration are omitted. Requests to draft remain drafts; requests to save
or update a specific note authorize that change, followed by a readback. Tax preparation establishes
jurisdiction/year before applying current official rules. Health is deferred.

The two connectors and their transitive dependencies are integrity-locked under
`modules/home-manager/core/opencode/assistant/connectors/` and packaged with Node 24. They run
locally over stdio; no public MCP service or runtime package download is needed. AFFiNE remains
behind Tailscale. The assistant reads only the service needed for the current request. Local
connectors still send tool results to the configured model.

After the authorized system activation, enter credentials in your own terminal:

```sh
opencode-assistant setup actualbudget
opencode-assistant setup affine
opencode-assistant status
```

For Gmail, deploy the Google MCP callback change, activate this harness, then run
`opencode mcp auth google` and complete the browser sign-in as `ushiradineth@gmail.com`. OpenCode
requests identity and Gmail read-only scopes and manages its own tokens outside this repository. The
Gmail profile selects a tailnet-protected route that supplies the matching OAuth scope hint, so the
shared server's broader advertisement does not expand this request. The server allowlist adds
OpenCode's exact callback `http://127.0.0.1:19876/mcp/oauth/callback` while retaining the existing
app callback. Its shared server permissions stay unchanged; the explicit OpenCode tool allowlist
limits this assistant. `opencode mcp debug google` diagnoses discovery and authentication without
treating registration as proof of mailbox access.

The setup commands use the helper installed by the OpenCode Home Manager module. Passwords are
hidden and saved in mode-0600 files under `~/.config/opencode-assistant/`, outside this repository
and the Nix store. The budget cache lives under `~/.local/share/opencode-assistant/`. XDG overrides
are respected. `status` proves configuration only. Restart OpenCode, inspect `opencode mcp list`,
then request a harmless budget read and an existing-note read to verify account access. Verify
writeback through an actual requested note change and readback; never create test transactions for
setup.

Changing `hosts/shupi/services/actualbudget.nix`, AFFiNE/Google deployment or connector code remains
engineering work in `jiyu`, with the normal repository checks and deployment boundaries.

Existing model and provider settings are preserved. Workers inherit the active model unless an
operator configures a role model in managed `opencode.json`. This setup does not pretend that two
same-model reviewers are a multi-model panel. Native OpenCode skill, task, todo and file tools
replace Cursor-specific calls.

Wakatime, notifications and terminal integration remain. The upstream context-mode plugin provides
indexed retrieval, large-output handling and compaction recovery; `jiyu-mode` owns the coding
workflow. Context-mode supplies its native tools and hooks without a duplicate MCP registration or
replacing project `AGENTS.md`. Use `ctx stats` in OpenCode to inspect it after activation.

Context-mode is pinned to `1.0.169`: `2.1.4` runs its hooks inside OpenCode's embedded Bun runtime
and rejects its reported Node version (`v24.3.0`). Updating the shell's Node does not change that
runtime. Advance the pin only after hooks, routing and a native `ctx_execute` call pass in the
packaged OpenCode binary.

Routine shell commands and checks retain ordinary execution permission. Destructive commands,
pushes, merges, deployment and system-switch commands retain approval patterns. These command
patterns do not replace the user's scope or repository boundaries.

OpenCode's scratch subtree under macOS's per-user temporary directory is allowed through
`/var/folders/*/*/T/opencode/**` and its `/private/var/folders/` alias. The changing
temporary-directory prefix does not need a new approval. Other temporary directories retain the
default external-access prompt.

## Project guidance and continuity

Keep project `AGENTS.md` factual: verified commands, architecture, conventions and operational
boundaries. Do not copy the global coding workflow into every project. Update project guidance when
the project changes or a repeated mistake reveals a missing rule.

`.agents/CONTEXT.md` is a short map of durable facts and useful task notes. Work spanning sessions
can keep its goal, current state, consequential decisions, verification, blockers and next action in
one note under `.agents/plans/`, linked to a decision log or other evidence when needed. Existing
useful project conventions can serve the same purpose. Routine edits do not need a plan or a round
of updates to `DECISIONS.md`, `PROGRESS.md` and `MEMORY.md` or `MEMORIES.md`.

Read relevant old notes for useful facts and completed work. Their former planner/builder rules are
historical. Preserve ongoing task records; do not delete or archive them merely because the harness
changed. Context-mode's session memory complements these artifacts and does not make old workflow
instructions authoritative.

## Skills and coverage

Every installed technique has native discovery. Coding techniques also have slash commands that run
in the current primary session. Commands select a technique; normal prompts let the router pick.

The complete upstream inventory was reviewed: 58 skills, including 24 principles, 23 playbooks, both
agents, the ten-chapter guide, the Claude adapter, helper inventory and generated harness layout.
The following choices keep the engineering methods while removing duplicate orchestration.

| Upstream capability                                                                         | OpenCode treatment                                                                                                                                                 |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| poteto-mode, poteto-help                                                                    | Local `jiyu-mode` default router and `jiyu-help` setup/use help.                                                                                                   |
| in-your-own-words, how, why, teach                                                          | Focused intent, mechanics, rationale and explanation skills.                                                                                                       |
| architect, arena, swarm                                                                     | Caller-first design, competing attempts and parallel coverage.                                                                                                     |
| interrogate, blast-radius, benchmark-checklist                                              | Correctness attack, cross-boundary safety and measured claims.                                                                                                     |
| figure-it-out, show-me-your-work                                                            | Designed long runs and auditable evidence trails.                                                                                                                  |
| no-comments, unslop, technical-writing                                                      | Comment review and prose standards.                                                                                                                                |
| tdd, typescript-best-practices                                                              | Native behavioral regressions and domain-oriented typing.                                                                                                          |
| create-verification-skill, maintain-verification-skill                                      | Proven project-local recipes under `.opencode/skills/`.                                                                                                            |
| correct                                                                                     | Enforce demonstrated repeated mistakes structurally.                                                                                                               |
| All 24 principle-\* skills                                                                  | Full rules retained as selectively loaded references.                                                                                                              |
| recall                                                                                      | Session pickup and task-local evidence in the continuity playbook; no default transcript mining.                                                                   |
| reflect, automate-me                                                                        | Requested harness/skill maintenance uses the authoring playbook; no automatic global edits or history mining.                                                      |
| setup-pstack                                                                                | Managed OpenCode model configuration is the single source; no separate Cursor rule file.                                                                           |
| bro, sharpen                                                                                | Plain-language replies and explicit prompt help stay inline; no extra workflow entrypoints.                                                                        |
| ketchup, ketchup-video                                                                      | Text catch-up retained; no automatic video-rendering pipeline.                                                                                                     |
| create-formal-verification-skill, maintain-formal-verification-skill, statechart            | Reviewed but not installed as generic defaults. A project needing formal proof should add its real toolchain, property and bounds, then prove that check can fail. |
| make-bot-ui, Benny automations                                                              | Cursor-specific webhook and automation setup is not installed.                                                                                                     |
| cursor-team-kit deslop, loop-on-ci, fix-merge-conflicts, thermo-nuclear-code-quality-review | Adapted native skills; the existing local deslop guidance is retained.                                                                                             |

The 23 upstream playbooks are covered without retaining 23 separate orchestration systems:

| Upstream playbooks                                           | Local route                                                                                                                      |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| Investigation, Runtime forensics, Trace forensics            | Investigation with the relevant live or captured evidence.                                                                       |
| Bug fix, Feature, Refactoring                                | Dedicated implementation playbooks.                                                                                              |
| Perf issue, Hillclimb                                        | Performance playbook with controlled measurement and hypothesis logging.                                                         |
| Prototype, Visual parity, Multi-phase plan                   | Design and feature routes with the actual prototype, frozen baseline or requested plan.                                          |
| Authoring a skill, Eval                                      | Skill-authoring playbook and isolated behavioral evaluation.                                                                     |
| Opening a PR, Babysit, Shipping                              | PR work, conflict resolution and attached-CI checks; status-only stays read-only.                                                |
| Autonomous run, Orchestrate, Autopilot-full, Autopilot-stack | Figure-it-out phases, bounded leaf work and the existing oc-loop when explicitly requested. A merge still needs merge authority. |
| Session pickup, Pause safely                                 | Continuity playbook.                                                                                                             |
| Worktree cleanup                                             | Scoped operational work from actual git state; no automatic deletion.                                                            |

Minecraft context, security auditing, local SAST, Fallow, Kumo design and personal voice remain for
their actual domains. ADHD presentation is opt-in. Personal voice uses unslop instead of the
duplicate humanizer workflow.

Retired coding machinery includes the planner/builder/direct/sudo lanes, role-specific handoff
templates, beam/redteam/sync commands and overlapping quality routers. Historical plans remain
evidence. They do not reactivate the retired lanes.

## Provenance and local changes

Seojiyu is the local name for this pstack adaptation. `jiyu-mode` and `jiyu-help` adapt upstream
`poteto-mode` and `poteto-help`; upstream package names, links and license notices remain intact.

Pstack and cursor-team-kit source:
[cursor/plugins at c742dd61706fbacc1b95f1a20b7b988cf096ce6c](https://github.com/cursor/plugins/tree/c742dd61706fbacc1b95f1a20b7b988cf096ce6c/pstack),
pstack version 0.15.36, reviewed 2026-10-28. Read the
[upstream guide](https://github.com/cursor/plugins/tree/c742dd61706fbacc1b95f1a20b7b988cf096ce6c/pstack/docs/guide)
for the original methods. Each adapted skill carries the applicable upstream MIT license.

The [reference site](https://erictechpro.github.io/super-board/pstack/) was inspected through its
[published map data](https://github.com/erictechpro/super-board/tree/a2809b6a771113d07b5bfaeb7d38033a35245b8b/diagrams/pstack)
because direct page retrieval was unavailable. Its map describes pstack 0.15.17 and includes
Claude-port extras. The pinned upstream source governs this adaptation.

Local changes replace Cursor tool/model fields, fixed fan-out and forced PR creation with native
OpenCode roles and task-sized execution. Explicit approval checkpoints remain explicit; a request to
implement includes ordinary design decisions. Cleanup preserves real constraints. Source-backed
review concerns that cannot be reproduced remain visibly unverified. Broad gates run at coherent
integration boundaries, and existing evidence is reused while its inputs remain unchanged.

To update upstream, compare the candidate revision with this pin, review the affected full skill and
references, preserve notices, and test the resulting decision behavior and native discovery. Do not
overwrite the adaptation with a moving main-branch download.

## Validate and activate

Run `just fmt`, `just check`, and `just build-dry` from the repository root. The flake checks
evaluate configuration and package coherence, exercise native OpenCode discovery, roles, commands
and edit enforcement in isolated homes, test the TSV helper, and validate specialist exporters.
Prompt packaging and routing scenarios do not prove that future code quality has improved.

Activation uses the repository's `just build` system switch and needs explicit authorization under
the root AGENTS.md. Restart OpenCode afterwards and start a new `jiyu` session. Old sessions may
retain their old prompt or agent name; there are no compatibility lanes. Source checks and a dry
build alone do not prove activation.
