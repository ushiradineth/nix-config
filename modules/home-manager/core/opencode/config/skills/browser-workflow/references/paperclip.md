# Native Paperclip browser execution

Keep native provider execution on `shupi`. Only a worker with existing verified SSH/tool eligibility
may dispatch to `shu`; loading this skill grants no authority. Resolve skills by semantic catalog
lookup because runtime names may be suffixed. The installed Mac helper is authoritative; an exported
Python script on `shupi` is not installation evidence.

Verify the executable path against the approved Darwin output. Health uses this fixed argv:

```sh
ssh -T -o BatchMode=yes -o ConnectTimeout=10 shu /run/current-system/sw/bin/agent-browser-task --health
```

For requests, omit only `--health` and pass the [JSON contract](shu.md) on stdin with
`caller: "paperclip"`, actual native run ID and distinct session ID. Keep SSH command text fixed;
never interpolate URLs, selectors, IDs or JSON into the remote shell. No PTY, agent/port forwarding,
CDP/MCP/dashboard listener, credentials or personal profile attachment. Bound the SSH subprocess to
30 seconds; close the same session in a finally path. If SSH is unavailable, report the bounded
failure and cleanup `needs_validation`; idle recovery is a fallback, not observed closure.

## Screenshot delivery

1. Call `screenshot` with a fresh basename, then `artifact-read` before `close`.
2. Decode returned base64 into a task-owned native workspace file with a relative basename. Verify
   exact bytes, `size`, PNG signature and SHA-256; the Mac path alone is not deliverable.
3. Discover the native artifact/viewer tools from the actual run's advertised inventory.
   `register_deliverable` uses a workspace-relative `contentRef`, exact byte size and SHA-256. Use
   the currently advertised schema, never invent payload fields or upload endpoints. Prefer a
   root-level basename for both `filename` and `contentRef`: this was verified with the pinned
   runner, whereas nested-path calls failed provider JSON Schema validation. The tested inputs are
   `idempotencyKey`, `filename`, `contentType`, `byteSize` (number), `sha256`, `contentRef`, and
   `title`, without a wrapper or extra fields. On a schema rejection, stop the upload loop and
   inspect the contract; do not retry unchanged calls or bypass it through an unrelated route.
4. Registration does not render an image. Use a provider image viewer only when advertised and
   record the inspection result. Otherwise mark visual inspection `needs_validation`.

An actual native pilot must reproduce the disposable fixture flow, concurrent storage isolation,
desktop/mobile captures, console/errors checks, screenshot retrieval/inspection and targeted
cleanup. A local test or host-side SSH substituted for that run does not prove the native path.
Existing same-user SSH can bypass these browser guardrails; this workflow does not add an OS sandbox
or change SSH restrictions.
