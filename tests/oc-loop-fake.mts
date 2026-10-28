import assert from "node:assert/strict"
import { appendFileSync, readFileSync, writeFileSync } from "node:fs"
import { createServer } from "node:http"
import type { Turn } from "./oc-loop.test.mts"
import type { AutonomyHooks, AutonomyOptions } from "../scripts/oc-loop-autonomy.mjs"

const session = "ses_test123"
const root = process.env.FAKE_ROOT
assert.ok(root)
const config = JSON.parse(process.env.OPENCODE_CONFIG_CONTENT || "{}") as {
  plugin?: (string | [string, AutonomyOptions])[]
}
const injected = config.plugin?.find(
  (spec): spec is [string, AutonomyOptions] =>
    Array.isArray(spec) && spec[0].includes("oc-loop-autonomy.mjs")
)
let hooks: AutonomyHooks | undefined
if (injected && !process.env.FAKE_AUTONOMY_DISABLED) {
  const plugin: typeof import("../scripts/oc-loop-autonomy.mjs") = await import(injected[0])
  hooks = await plugin.default(
    {
      directory: process.cwd(),
      client: {
        _client: {
          get: async (request) => ({
            data:
              request.url === "/permission" && process.env.FAKE_REPLY_FAILURE
                ? [{ id: "per_fixture", sessionID: session }]
                : request.url.startsWith("/session/")
                  ? { id: request.path.sessionID }
                  : [],
          }),
          post: async (request) => {
            if (process.env.FAKE_REPLY_RACE || process.env.FAKE_REPLY_FAILURE)
              return { error: { name: "ReplyConflict" } }
            appendFileSync(root + "/answers.jsonl", JSON.stringify(request) + "\n")
            return { data: true }
          },
        },
      },
    },
    injected[1]
  )
}
if (process.argv[2] === "serve") {
  const server = createServer((req, res) => {
    const expected =
      "Basic " + Buffer.from("opencode:" + process.env.OPENCODE_SERVER_PASSWORD).toString("base64")
    if (req.headers.authorization !== expected) {
      res.writeHead(401)
      res.end("{}")
      return
    }
    appendFileSync(
      root + "/requests.jsonl",
      JSON.stringify({ path: req.url, directory: req.headers["x-opencode-directory"] }) + "\n"
    )
    res.setHeader("Content-Type", "application/json")
    if (req.url === "/session/status") {
      let busy = false
      try {
        busy = readFileSync(root + "/manual-busy", "utf8") === "yes"
      } catch {}
      const wrongInstance =
        process.env.FAKE_REQUIRE_ORIGIN &&
        req.headers["x-opencode-directory"] !== process.env.FAKE_SESSION_ORIGIN
      res.end(JSON.stringify(busy && !wrongInstance ? { [session]: { type: "busy" } } : {}))
    } else if (req.url?.includes("/message")) {
      try {
        res.end(readFileSync(root + "/messages.json", "utf8"))
      } catch {
        res.end("[]")
      }
    } else
      res.end(JSON.stringify({ id: session, directory: process.env.FAKE_SESSION_ORIGIN || root }))
  })
  server.listen(0, "127.0.0.1", () => {
    const address = server.address()
    assert.ok(address && typeof address !== "string")
    console.log("opencode server listening on http://127.0.0.1:" + address.port)
  })
  await new Promise(() => {})
}
if (process.argv[2] === "attach") {
  appendFileSync(
    root + "/attachments.jsonl",
    JSON.stringify({ args: process.argv.slice(2), tui: process.env.OPENCODE_TUI_CONFIG }) + "\n"
  )
  process.exit(0)
}
let calls: string[] = []
try {
  calls = readFileSync(root + "/calls.jsonl", "utf8")
    .trim()
    .split("\n")
} catch {}
appendFileSync(
  root + "/calls.jsonl",
  JSON.stringify({ args: process.argv.slice(2), stdin: readFileSync(0, "utf8"), config }) + "\n"
)
const turns = JSON.parse(readFileSync(root + "/turns.json", "utf8")) as Turn[]
const next = turns[calls.length]
if (!next) {
  console.error("Unexpected extra turn")
  process.exit(99)
}
// Native sessions execute in their origin instance. Listening in another instance
// misses permission/terminal events even though session metadata is globally readable.
if (
  process.env.FAKE_REQUIRE_ORIGIN &&
  process.argv[process.argv.indexOf("--dir") + 1] !== process.env.FAKE_SESSION_ORIGIN
)
  process.exit(0)
if (next.persisted)
  writeFileSync(
    root + "/messages.json",
    JSON.stringify([
      {
        info: {
          id: "msg_persisted",
          role: "assistant",
          time: { created: Date.now(), completed: Date.now() },
          ...next.persisted.info,
        },
        parts: [{ type: "text", text: next.persisted.text }],
      },
    ])
  )
for (const event of next.events ?? []) {
  if (
    typeof event !== "string" &&
    "properties" in event &&
    (event.type === "question.asked" ||
      event.type === "permission.asked" ||
      event.type === "session.created")
  ) {
    await hooks?.event({ event })
  } else console.log(typeof event === "string" ? event : JSON.stringify(event))
}
if (next.stderr) console.error(next.stderr)
if (next.wait) {
  writeFileSync(root + "/child.pid", String(process.pid))
  await new Promise(() => setInterval(() => {}, 1000))
}
process.exit(next.code ?? 0)
