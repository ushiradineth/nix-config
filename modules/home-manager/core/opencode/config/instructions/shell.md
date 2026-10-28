# Shell use

Use repository commands and noninteractive execution. Disable pagers and interactive credential
prompts when needed. A command that requires a terminal may use a controlled PTY; do not leave
editors, REPLs or prompts waiting unattended.

Use explicit flags appropriate to the operation. Do not add `--force`, `--yes` or overwrite flags
just to suppress a meaningful approval. Prefer file tools for edits.

Use existing tools and the repository's development shell. For missing one-off tools, prefer
`nix shell nixpkgs#<package> -c <command>`; do not install global dependencies unnecessarily. Follow
the repository's package manager and lockfile. Otherwise prefer pnpm for Node projects.

Batch independent reads and checks. Keep dependent edits and verification sequential. Bound commands
that might hang, and poll long jobs without losing their exit status. Summarize relevant failures;
do not turn a failed command into a passing result with `|| true`.
