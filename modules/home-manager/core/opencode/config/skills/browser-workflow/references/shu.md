# Browser requests on shu

The Nix host module installs `agent-browser-task` with isolated Nix Python. It uses the existing
`/opt/homebrew/bin/agent-browser` 0.39.1 and the installed Google Chrome application executable,
with a fresh task HOME and explicit empty plugin/extension config. It does not install a browser.
Run `agent-browser-task --health`; compatibility and runtime presence do not prove launch/render.
Approved system activation and real-browser smoke remain separate gates.

## JSON stdin contract

Send the following object to `agent-browser-task` on stdin, closing stdin after the JSON. The
initial request must be `open` with the exact authorized `initial_url`.

```json
{
  "caller": "opencode",
  "run_id": "approved-run-id",
  "session_id": "fixture-desktop",
  "mode": "local-test",
  "initial_url": "http://127.0.0.1:8123/",
  "domains": ["127.0.0.1"],
  "command": "open",
  "args": ["http://127.0.0.1:8123/"],
  "timeout_ms": 20000
}
```

Replace the sample URL with the approved disposable server's actual random-port URL, never infer
authority from the example. IDs are 1-64 ASCII letters/digits/underscores/hyphens, starting with a
letter/digit. Use a new session ID after closure or idle recovery; the old scope is never widened or
restarted. `public-read` requires HTTPS on port 443 and exact public domains, without wildcards or
credentials in the URL. DNS/network controls are not OS-enforced isolation.

| Command                     | Args                                            | Modes      |
| --------------------------- | ----------------------------------------------- | ---------- |
| `open`                      | `[authorized_url]`                              | Both       |
| `snapshot`                  | `[]`                                            | Both       |
| `get`                       | `["url"]`, `["title"]`, or `["text", selector]` | Both       |
| `viewport`                  | `["1280", "800"]` or `["390", "844"]`           | Both       |
| `console`, `errors`         | `[]`                                            | Both       |
| `screenshot`                | `["desktop.png"]`                               | Both       |
| `artifact-read`             | `["desktop.png"]`                               | Both       |
| `close`                     | `[]`                                            | Both       |
| `click`, `check`, `uncheck` | `[selector]`                                    | Local-test |
| `fill`, `select`            | `[selector, value]`                             | Local-test |
| `drag`                      | `[source_selector, target_selector]`            | Local-test |

Use snapshots and `@eN` refs or fixture selectors; arbitrary JS/eval, auth, cookies/storage,
uploads/downloads, shell/batch, extra flags, providers, restore/state, headers/proxy, profile/CDP,
auto-connect, extensions/plugins, WebMCP and close-all are rejected. Local URL scope is checked
before every page interaction/read and after browser actions; unexpected navigation closes the owned
session and suppresses its response. Domain controls cannot prevent every effect of page JS or race
with asynchronous navigation, so use only credential-free public/disposable pages.

## Bounds and evidence

Input is at most 16 KiB with a 5-second stdin deadline. At most three args, 4096 characters each; no
option-shaped args or control characters. Request timeout is 500-20000 ms (default 20000), each
browser subprocess at most 8 seconds, action timeout 5 seconds, cleanup 2 seconds, idle recovery 60
seconds. Browser stdout/stderr is capped at 64 KiB; page output at 24000 characters. Never treat
`truncated: true` as complete evidence. On failure, the helper kills only the request subprocess and
attempts targeted close; `cleanup: needs_validation` requires follow-up.

Owner-only task directories hold immutable scope/config, private HOME and artifacts under
`/private/tmp/abt-<uid>` on macOS (`/tmp/abt-<uid>` elsewhere), independent of ambient `TMPDIR`.
They retain evidence after close, without restore/state reuse. Artifact names are single new
basenames ending in `.png`, never absolute paths or subdirectories. Symlinks/hardlinks/special files
are rejected. Retrieve before closing with `artifact-read`: `artifact` contains `name`, `size`,
`sha256`, `base64`, bounded to 2 MiB of exact PNG bytes. Decode locally and verify the byte count
and SHA-256. No image-inspection claim follows from that metadata.

Source tests: `python3 tests/agent-browser-task-test.py`. After approved installation:
`python3 tests/agent-browser-smoke.py --local`. To validate a built candidate before activation, add
`--helper /absolute/path/to/bin/agent-browser-task`. The smoke owns a random-port server, exercises
whitespace rejection, valid form submission/navigation, desktop/mobile captures and concurrent
storage markers, then closes its sessions/server. Visual semantics and native SSH execution are
separate acceptance evidence. Seed a later regression defect only in disposable fixture copies.
