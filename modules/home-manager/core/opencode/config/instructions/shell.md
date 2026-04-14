# Shell Non-Interactive Policy

No TTY or PTY. Any prompt can hang.

## Rules

- Run as CI.
- Never run interactive editors, pagers, REPLs, or shell modes.
- Always use non-interactive flags when available: `-y`, `--yes`, `--no-input`, `--force`.
- Prefer OpenCode file tools over shell file editing.
- Continue after each tool result until the task is complete.
- Add `timeout` when a command might block.

## Nix tools and shells

- If a dependency is missing, use Nix first.
- Do not default to `apt`, `brew`, curl-install scripts, or global installs.
- One-off:

  ```bash
  nix shell nixpkgs#<pkg> -c <command>
  ```

- Multiple tools:

  ```bash
  nix shell nixpkgs#jq nixpkgs#fd nixpkgs#ripgrep -c <command>
  ```

- Repo shell:

  ```bash
  nix develop -c <command>
  ```

- Repeated tools should be added to flake or Home Manager config.

## JavaScript package manager

- Default to `pnpm`.
- Use `npm`, `yarn`, or `bun` only if user or repo requires it.
- Standard commands: `pnpm install --frozen-lockfile --reporter=silent`, `pnpm add <pkg>`,
  `pnpm remove <pkg>`, `pnpm run <script>`, `pnpm dlx <tool>`.

## Environment guards

- `CI=true`
- `GIT_TERMINAL_PROMPT=0`
- `GIT_EDITOR=true`
- `GIT_PAGER=cat`
- `PAGER=cat`
- `GCM_INTERACTIVE=never`
- `npm_config_yes=true`
- `PIP_NO_INPUT=1`

## Safe patterns

- Git: `git commit -m "msg"`, `git merge --no-edit <branch>`, `git pull --no-edit`,
  `git --no-pager log -n 20`, `git --no-pager diff`
- Files: `rm -f`, `cp -f`, `mv -f`, `unzip -o`
- Network: `curl -fsSL`, `wget -q`
- Docker: never use `-it`
- Python or Node: run scripts, `-c`, or `-e`, never bare REPL

## Forbidden interactive commands

- Editors: `vim`, `vi`, `nano`, `emacs`
- Pagers: `less`, `more`, `man`
- Interactive git: `git add -p`, `git rebase -i`, `git commit` without `-m`
- Interactive shells: `bash -i`, `zsh -i`
- Bare REPLs: `python`, `node`, `irb`, `ghci`

## Fallback when no non-interactive flag exists

```bash
yes | <command>
<command> <<'EOF'
...
EOF
timeout 30 <command> || echo "Timed out"
```
