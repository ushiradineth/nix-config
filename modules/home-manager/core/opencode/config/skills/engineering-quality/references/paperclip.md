# Paperclip runtime mapping

Preserve the shared quality gates without importing OpenCode's control syntax or permissions.

| OpenCode convention                         | Paperclip equivalent                                                                          |
| ------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Accepted plan and fresh builder session     | Approved issue/plan artifact with explicit scope and done criteria.                           |
| `.agents` execution state                   | Issue updates, project artifacts, and durable task checkpoints.                               |
| User-visible lane or optional slash command | Existing role plus task contract; no automatic primary-agent launch.                          |
| Runtime `task` helper                       | Authorized bounded child issue with named owner and evidence, when delegation is useful.      |
| Shared skill folder name                    | Semantic skill identity resolved from the current inventory; runtime names can have suffixes. |
| Local test command                          | Same repository check in the task's authorized execution workspace.                           |

Keep the agent's managed role instructions and existing skills. Missing skill or tool access is a
blocker, not permission to create credentials, hire a worker, or modify the role/model/adapter. Use
semantic Paperclip tools when advertised; otherwise use only authorized documented APIs.

## Coding on shu

Use a task-owned copy/worktree under `/Users/shu/.paperclip/workspaces`. Do not automatically mount,
sync, or edit the user's active `~/Code` working tree. Record workspace, branch, commit, dirty
baseline, test commands, and output evidence in the issue. Existing SSH is same-user execution, not
a repository sandbox.

Read repository instructions in that workspace. Do not apply the whole OpenCode global AGENTS
contract as a second role definition. Skill references are relative to the installed skill package;
find packages by the current inventory, not hardcoded `CODEX_HOME` paths.

## Handoffs and browser evidence

Use child issues/checkpoints only within the authorized manager relationship. Do not recursively
launch runtime agents. Inline review stays inline unless the accepted task explicitly calls for an
independent reviewer.

For browser tests, load `browser-workflow` and its Paperclip reference. The browser runs on `shu`;
snapshots return over SSH and screenshots must be retrieved into the native run workspace. Register
them through the advertised deliverable mechanism after verifying byte size/hash. A remote path or
download URL alone does not prove that the agent visually inspected the image.

Completion reports name the accepted spec, changed files, commands/results, separate Standards/Spec
review outcomes, artifacts, unresolved risks, and the next owner/action for anything unverified.
