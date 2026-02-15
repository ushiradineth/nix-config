# AGENTS

Nearest `AGENTS.md` wins. Nested guides override parent guidance for files in their subtree.

## Commands

- Format: `just fmt`
- Full checks (CI-equivalent local gate): `just check`
- Direct check command:
  `nix flake check --all-systems --extra-experimental-features 'nix-command flakes'`
- macOS apply local host: `just build`
- macOS build only: `just build-dry`
- Linux apply local host: `just build`
- Linux build only: `just build-dry`
- Remote bootstrap: `just init <hostname>`
- Remote deploy via colmena tag: `just deploy <tag>`
- Remote deploy dry-run: `just deploy-dry <tag>`

## Testing

- Primary validation path: `just check`
- Flake checks include pre-commit hooks configured in `parts/development.nix`: `alejandra`,
  `prettier`, `deadnix`, `statix`
- Run formatter before check when touching multiple files: `just fmt && just check`
- For host-specific changes, run a non-switching build first: `just build-dry`
- confidence: low
- TODO: no `.github/workflows` found. Confirm whether CI runs `just check` externally.

## Project Structure

- Root composition in `flake.nix` imports `outputs/*` and `parts/*`
- Host outputs:
  - `outputs/linux/` for `nixosConfigurations`
  - `outputs/darwin/` for `darwinConfigurations`
  - `outputs/colmena/` for remote deployment nodes
- Reusable modules:
  - `modules/nix-modules/{core,darwin,linux}` for system modules
  - `modules/home-manager/{core,darwin,linux}` for user-space modules
- Shared helpers and data: `lib/`, `vars/`, `overlays/`
- Dev templates for other repos: `flakes/`
- Existing nested guide: `modules/home-manager/core/opencode/config/AGENTS.md`

## Code Style

- Nix formatting: enforced by `alejandra` via `just fmt`
- Markdown/YAML/JSON/CSS formatting: enforced by `prettier` with `.prettierrc.yaml`
- Shell formatting/linting in checks: `shfmt`, `shellcheck`
- Keep modules small and composable. Follow existing pattern of grouped attrs and `let ... in` where
  needed.
- Example (Nix attr formatting style):

```nix
{inputs, ...}: {
  imports = [
    ./core
    ./darwin
  ];
}
```

## Git Workflow

- Before edits: `git status --short && git diff && git diff --cached`
- Keep changes scoped. Do not include unrelated files in the same commit.
- Run `just fmt` for touched files, then `just check` before opening PR.
- Follow existing commit style from history: conventional-like prefixes (`feat:`, `fix:`,
  `refactor:`, `chore:`, `style:`)
- Do not amend or force-push unless explicitly requested.

## Boundaries

### Always

- Use commands from this file or verified repo docs only.
- Prefer dry-run/build-only flows (`just build-dry`, `just deploy-dry`) before apply/deploy.
- Keep secrets out of commits. This repo references private input `mysecrets` in `flake.nix`.
- Respect nearest-guide precedence when editing under nested `AGENTS.md` paths.

### Ask first

- Running switching/apply commands that mutate the active system (`just build`,
  `nixos-rebuild switch`, `darwin-rebuild switch`)
- Remote bootstrap/deployment commands (`just init`, `just deploy`)
- Changing secret wiring or private flake inputs (`mysecrets`, agenix-related paths)
- Updating `flake.lock` or broad input upgrades (`just up`, `just upp <input>`) when not explicitly
  requested

### Never

- Commit credentials, keys, tokens, or decrypted secret material
- Bypass hooks with `--no-verify` or similar flags
- Use destructive git operations (`reset --hard`, force push) without explicit instruction

## Verification Checklist

- [ ] `just fmt`
- [ ] `just check`
- [ ] If host-specific: `just build-dry`
- [ ] If remote-specific: `just deploy-dry <tag>`
- [ ] `git status --short` shows only intended files
