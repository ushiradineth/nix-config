# Safe local DAST

Dynamic scanning is never an automatic readiness step. It requires explicit user intent and a
reviewed disposable local harness.

## Required topology

- Build the current checkout into a disposable local image.
- Use exact image digests for scanner and supporting services.
- Put every runtime service on one Docker network with `internal: true` and no implicit/default
  network attachment.
- Publish no application or database host ports. Use hardcoded dummy values, ephemeral state, and no
  env files or real secrets.
- Mount only the report directory writable. Cap CPU, memory, process count, health timeouts, and the
  overall scan duration.
- Start database, migration, application, and scanner through health/completion gates.
- Use passive ZAP baseline only: `zap-baseline.py -I`. Do not use full, API, active, or
  authenticated scans.
- Use a unique Compose project and always remove containers, networks, and volumes on exit.

## Fail closed before execution

The wrapper must reject `DOCKER_HOST`, non-`unix://` Docker contexts, arbitrary target arguments,
published ports, env files, external/default networks, unexpected mounts, unpinned external images,
missing health gates, and non-passive scanner commands.

Provide a static `--check` path that renders Compose and verifies these invariants without starting
containers. Agents may run that static check. The first dynamic run remains user-owned and
`needs_validation` until the user reviews the harness and authorizes it.

Production, staging, shared services, shupi, and user-supplied URLs are never valid targets for this
workflow.
