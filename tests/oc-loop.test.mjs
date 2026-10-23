import assert from "node:assert/strict"
import { spawn, spawnSync } from "node:child_process"
import { createHash, randomUUID } from "node:crypto"
import {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs"
import { tmpdir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { fileURLToPath, pathToFileURL } from "node:url"
import { test } from "node:test"

const script = resolve(dirname(fileURLToPath(import.meta.url)), "../scripts/oc-loop.mjs")
const executable = process.env.OC_LOOP_TEST_BINARY || process.execPath
const session = "ses_test123"
const token = "PROJECT_ENTIRELY_COMPLETE"

function turn(text, messageID = "msg_final", reason = "stop") {
  return [
    { type: "step_start", sessionID: session, part: { messageID } },
    { type: "text", sessionID: session, part: { messageID, text } },
    { type: "step_finish", sessionID: session, part: { messageID, reason } },
  ]
}

function fixture(t, turns) {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "oc-loop test-")))
  t.after(() => rmSync(root, { recursive: true, force: true }))
  const fake = join(root, "opencode")
  writeFileSync(join(root, "turns.json"), JSON.stringify(turns))
  writeFileSync(
    fake,
    `#!${process.execPath}
import { appendFileSync, readFileSync, writeFileSync } from "node:fs"
import { createServer } from "node:http"
const root = process.env.FAKE_ROOT
const config = JSON.parse(process.env.OPENCODE_CONFIG_CONTENT || "{}")
const injected = (config.plugin || []).find((spec) => Array.isArray(spec) && spec[0].includes("oc-loop-autonomy.mjs"))
let hooks
if (injected && !process.env.FAKE_AUTONOMY_DISABLED) {
  const plugin = await import(injected[0])
  hooks = await plugin.default({
    directory: process.cwd(),
    client: { _client: { post: async (request) => {
      appendFileSync(root + "/answers.jsonl", JSON.stringify(request) + "\\n")
      return { data: true }
    } } },
  }, injected[1])
}
if (process.argv[2] === "serve") {
  const server = createServer((req, res) => {
    const expected = "Basic " + Buffer.from("opencode:" + process.env.OPENCODE_SERVER_PASSWORD).toString("base64")
    if (req.headers.authorization !== expected) { res.writeHead(401); res.end("{}"); return }
    res.setHeader("Content-Type", "application/json")
    if (req.url === "/session/status") {
      let busy = false
      try { busy = readFileSync(root + "/manual-busy", "utf8") === "yes" } catch {}
      res.end(JSON.stringify(busy ? { ${JSON.stringify(session)}: { type: "busy" } } : {}))
    } else if (req.url.includes("/message")) {
      try { res.end(readFileSync(root + "/messages.json", "utf8")) } catch { res.end("[]") }
    }
    else res.end(JSON.stringify({ id: ${JSON.stringify(session)}, directory: process.env.FAKE_SESSION_ORIGIN || root }))
  })
  server.listen(0, "127.0.0.1", () => console.log("opencode server listening on http://127.0.0.1:" + server.address().port))
  await new Promise(() => {})
}
if (process.argv[2] === "attach") {
  appendFileSync(root + "/attachments.jsonl", JSON.stringify({ args: process.argv.slice(2), tui: process.env.OPENCODE_TUI_CONFIG }) + "\\n")
  process.exit(0)
}
let calls = []
try { calls = readFileSync(root + "/calls.jsonl", "utf8").trim().split("\\n") } catch {}
appendFileSync(root + "/calls.jsonl", JSON.stringify({ args: process.argv.slice(2), stdin: readFileSync(0, "utf8"), config }) + "\\n")
const turns = JSON.parse(readFileSync(root + "/turns.json", "utf8"))
const next = turns[calls.length]
if (!next) { console.error("Unexpected extra turn"); process.exit(99) }
if (next.persisted) writeFileSync(root + "/messages.json", JSON.stringify([{
  info: { id: "msg_persisted", role: "assistant", time: { created: Date.now(), completed: Date.now() }, ...next.persisted.info },
  parts: [{ type: "text", text: next.persisted.text }],
}]))
for (const event of next.events ?? []) {
  if (event.type === "question.asked" || event.type === "session.created") {
    await hooks?.event({ event })
  } else console.log(typeof event === "string" ? event : JSON.stringify(event))
}
if (next.stderr) console.error(next.stderr)
if (next.wait) {
  writeFileSync(root + "/child.pid", String(process.pid))
  await new Promise(() => setInterval(() => {}, 1000))
}
process.exit(next.code ?? 0)
`
  )
  chmodSync(fake, 0o700)
  const args = [
    ...(process.env.OC_LOOP_TEST_BINARY ? [] : [script]),
    "--foreground",
    "--dir",
    root,
    "--session",
    session,
    "--prompt",
    "Continue the approved project; fix the next unfinished task.",
    "--done-token",
    token,
    "--retry-delay",
    "0",
  ]
  const env = {
    ...process.env,
    XDG_STATE_HOME: join(root, "state"),
    OC_LOOP_OPENCODE: fake,
    FAKE_ROOT: root,
  }
  return {
    root,
    args,
    env,
    state: join(root, ".agents", "oc-loop", session),
    run(extra = []) {
      return spawnSync(executable, [...args, "--max-retries", "0", ...extra], {
        env,
        encoding: "utf8",
        timeout: 15000,
      })
    },
    resume(prompt) {
      return spawnSync(
        executable,
        [
          ...(process.env.OC_LOOP_TEST_BINARY ? [] : [script]),
          "resume",
          "--dir",
          root,
          "--session",
          session,
          "--prompt",
          prompt,
        ],
        { env, encoding: "utf8", timeout: 15000 }
      )
    },
    command(command, extra = []) {
      return spawnSync(
        executable,
        [
          ...(process.env.OC_LOOP_TEST_BINARY ? [] : [script]),
          command,
          "--dir",
          root,
          "--session",
          session,
          ...extra,
        ],
        { env, encoding: "utf8", timeout: 15000 }
      )
    },
    calls() {
      return readFileSync(join(root, "calls.jsonl"), "utf8").trim().split("\n").map(JSON.parse)
    },
  }
}

test("resumes the exact session after ordinary stops and completes only on the final token", (t) => {
  const f = fixture(t, [
    { events: turn("Step limit reached. More work remains.") },
    { events: turn("Validation passed for this milestone. Continuing next time.") },
    { events: turn(token) },
  ])
  const result = f.run()
  assert.equal(result.status, 0, result.stderr)
  assert.match(result.stdout, /DONE/)
  assert.equal(f.calls().length, 3)
  for (const call of f.calls()) {
    assert.deepEqual(call.args, [
      "run",
      "--attach",
      call.args[2],
      "--dir",
      f.root,
      "--session",
      session,
      "--format",
      "json",
      "--auto",
    ])
    assert.match(call.args[2], /^http:\/\/127\.0\.0\.1:\d+$/)
    assert.match(call.stdin, /Continue the approved project/)
    assert.match(call.stdin, /PROJECT_ENTIRELY_COMPLETE/)
    assert.ok(call.args.includes("--auto"))
  }
})

test("an explicit project directory supports a session originally created in another workspace", (t) => {
  const f = fixture(t, [{ events: turn(token) }])
  f.env.FAKE_SESSION_ORIGIN = "/original/session/workspace"
  const result = f.run()
  assert.equal(result.status, 0, result.stderr)
  assert.equal(state(f).directory, f.root)
  assert.equal(state(f).status, "DONE")
  assert.equal(f.calls()[0].args[f.calls()[0].args.indexOf("--dir") + 1], f.root)
})

test("tokens in tools, other sessions, summaries, earlier steps or unfinished responses never complete", (t) => {
  const falseSignals = [
    [
      ...turn("Working"),
      {
        type: "tool_use",
        sessionID: session,
        part: { messageID: "msg_final", state: { output: token } },
      },
    ],
    [...turn("Working"), ...turn(token).map((event) => ({ ...event, sessionID: "ses_other" }))],
    turn(`The instruction says to output ${token} when complete.`),
    [...turn(token, "msg_old"), ...turn("Actually, there is more work.", "msg_new")],
    turn(token, "msg_final", "length"),
  ]
  for (const events of falseSignals) {
    const f = fixture(t, [{ events }, { events: turn(token) }])
    const result = f.run()
    assert.equal(result.status, 0, result.stderr)
    assert.equal(f.calls().length, 2)
  }
})

test("permission/session errors never complete and honor an explicit zero retry budget", (t) => {
  const blockers = [
    ["! permission requested: bash (git commit); auto-rejecting", ...turn(token)],
    [
      {
        type: "error",
        sessionID: session,
        error: { name: "ProviderAuthError", data: { message: "Unauthorized" } },
      },
      ...turn(token),
    ],
    [
      {
        type: "tool_use",
        sessionID: session,
        part: {
          messageID: "msg_final",
          tool: "question",
          state: { status: "error", error: "Question unavailable" },
        },
      },
      ...turn(token),
    ],
  ]
  for (const events of blockers) {
    const f = fixture(t, [{ events }])
    const result = f.run()
    assert.equal(result.status, 2, result.stderr)
    assert.doesNotMatch(result.stdout, /^DONE/m)
    assert.equal(f.calls().length, 1)
    assert.equal(JSON.parse(readFileSync(join(f.state, "status.json"))).status, "BLOCKED")
  }
})

test("missing or malformed terminal events honor an explicit zero retry budget", (t) => {
  for (const events of [[], ["{not json"], turn(token).slice(0, 2)]) {
    const f = fixture(t, [{ events }])
    const result = f.run()
    assert.equal(result.status, 2, result.stderr)
    assert.equal(f.calls().length, 1)
  }
})

test("native permission warnings on stderr block completion even with a successful final response", (t) => {
  const f = fixture(t, [
    {
      events: turn(token),
      stderr: "\u001b[93m!\u001b[0m permission requested: bash (git commit); auto-rejecting",
    },
  ])
  const result = f.run()
  assert.equal(result.status, 2, result.stderr)
  assert.match(result.stderr, /permission/i)
  assert.equal(f.calls().length, 1)
})

test("failed turns honor an explicitly finite retry budget without falsely completing", (t) => {
  const failure = {
    events: [
      {
        type: "error",
        sessionID: session,
        error: { name: "APIError", data: { message: "HTTP 429 rate limit" } },
      },
    ],
    code: 1,
  }
  const recovered = fixture(t, [failure, { events: turn(token) }])
  assert.equal(recovered.run(["--max-retries", "3"]).status, 0)
  assert.equal(recovered.calls().length, 2)
  const exhausted = fixture(t, [failure, failure, failure])
  const result = exhausted.run(["--max-retries", "2"])
  assert.equal(result.status, 2, result.stderr)
  assert.equal(exhausted.calls().length, 3)
  assert.match(result.stderr, /retries exhausted/i)
})

test("temporarily unavailable provider errors retry rather than blocking immediately", (t) => {
  const f = fixture(t, [
    { stderr: "Upstream temporarily unavailable", code: 1 },
    { events: turn(token) },
  ])
  const result = f.run(["--max-retries", "3"])
  assert.equal(result.status, 0, result.stderr)
  assert.equal(f.calls().length, 2)
})

test("questions choose only the first option for the owned session and its new children", (t) => {
  const question = (sessionID, id, questions) => ({
    type: "question.asked",
    properties: { sessionID, id, questions },
  })
  const questions = [
    {
      question: "Which approach?",
      header: "Approach",
      options: [{ label: "First" }, { label: "Second (Recommended)" }],
    },
    {
      question: "Which checks?",
      header: "Checks",
      multiple: true,
      options: [{ label: "Unit tests" }, { label: "Everything" }],
    },
  ]
  const f = fixture(t, [
    {
      events: [
        question("ses_unrelated", "que_unrelated", questions),
        question(session, "que_root", questions),
        { type: "session.created", properties: { info: { id: "ses_child", parentID: session } } },
        question("ses_child", "que_child", questions),
        {
          type: "tool_use",
          sessionID: session,
          part: { messageID: "msg_question", tool: "question", state: { status: "completed" } },
        },
        ...turn(token),
      ],
    },
  ])
  const result = f.run()
  assert.equal(result.status, 0, result.stderr)
  const answers = readFileSync(join(f.root, "answers.jsonl"), "utf8")
    .trim()
    .split("\n")
    .map(JSON.parse)
  assert.deepEqual(
    answers.map((reply) => reply.path.requestID),
    ["que_root", "que_child"]
  )
  for (const reply of answers) {
    assert.equal(reply.url, "/question/{requestID}/reply")
    assert.deepEqual(reply.body, { answers: [["First"], ["Unit tests"]] })
    assert.equal(reply.query.directory, f.root)
  }
})

test("failed turns retry without a budget by default, including auth failures and timeouts", (t) => {
  const f = fixture(t, [
    { stderr: "Authentication temporarily unavailable", code: 1 },
    { stderr: "Invalid provider configuration", code: 1 },
    { wait: true },
    { events: turn(token) },
  ])
  const result = spawnSync(executable, [...f.args, "--turn-timeout", "1"], {
    env: f.env,
    encoding: "utf8",
    timeout: 15000,
  })
  assert.equal(result.status, 0, result.stderr)
  assert.equal(f.calls().length, 4)
  assert.match(result.stderr, /retry 3\/unlimited/)
})

test("the helper preserves injected config, never trusts an absent helper, and answers option-less questions", (t) => {
  const f = fixture(t, [
    {
      events: [
        {
          type: "question.asked",
          properties: {
            sessionID: session,
            id: "que_empty",
            questions: [{ question: "Continue?", header: "Continue", options: [] }],
          },
        },
        ...turn(token),
      ],
    },
  ])
  const original = {
    model: "existing/model",
    permission: { edit: "deny" },
    plugin: ["existing-plugin"],
  }
  f.env.OPENCODE_CONFIG_CONTENT = JSON.stringify(original)
  const result = f.run()
  assert.equal(result.status, 0, result.stderr)
  assert.equal(f.calls()[0].config.model, original.model)
  assert.deepEqual(f.calls()[0].config.permission, original.permission)
  assert.equal(f.calls()[0].config.plugin[0], "existing-plugin")
  assert.deepEqual(JSON.parse(readFileSync(join(f.root, "answers.jsonl"), "utf8")).body.answers, [
    ["Use your best judgment within the agreed scope and continue."],
  ])

  const disabled = fixture(t, [{ events: turn(token) }])
  disabled.env.FAKE_AUTONOMY_DISABLED = "1"
  const absent = disabled.run()
  assert.equal(absent.status, 2, absent.stderr)
  assert.match(absent.stderr, /helper did not load/)
})

test("logs and status are private, completion does not carry over to a later run", (t) => {
  const f = fixture(t, [
    { events: turn(token) },
    { events: turn("Still working") },
    { events: turn(token) },
  ])
  assert.equal(f.run().status, 0)
  assert.equal(f.run().status, 0)
  assert.equal(f.calls().length, 3)
  const status = JSON.parse(readFileSync(join(f.state, "status.json")))
  assert.equal(status.status, "DONE")
  assert.equal(status.turn, 2)
  assert.equal(statSync(f.state).mode & 0o777, 0o700)
  assert.equal(statSync(join(f.state, "status.json")).mode & 0o777, 0o600)
  const logs = readdirSync(f.state).filter((file) => file.endsWith(".jsonl"))
  assert.equal(logs.length, 2)
  for (const log of logs) assert.equal(statSync(join(f.state, log)).mode & 0o777, 0o600)
})

async function waitFor(predicate) {
  const deadline = Date.now() + 10000
  while (!predicate()) {
    if (Date.now() > deadline) throw new Error("Timed out waiting for fixture")
    await new Promise((resolve) => setTimeout(resolve, 20))
  }
}

function launch(t, f, extra = []) {
  const child = spawn(executable, [...f.args, "--max-retries", "0", ...extra], {
    env: f.env,
    stdio: ["ignore", "pipe", "pipe"],
  })
  let stdout = "",
    stderr = ""
  child.stdout.on("data", (data) => {
    stdout += data
  })
  child.stderr.on("data", (data) => {
    stderr += data
  })
  const exited = new Promise((resolve) =>
    child.once("close", (code) => resolve({ code, stdout, stderr }))
  )
  t.after(async () => {
    if (child.exitCode === null) child.kill("SIGTERM")
    const timer = setTimeout(() => {
      if (child.exitCode === null) child.kill("SIGKILL")
    }, 5000)
    try {
      await exited
    } finally {
      clearTimeout(timer)
    }
  })
  return { child, exited }
}

function state(f) {
  return JSON.parse(readFileSync(join(f.state, "status.json"), "utf8"))
}

test(
  "owner-only gates park the live runner without calls until an explicit same-session resume",
  { timeout: 15000 },
  async (t) => {
    const f = fixture(t, [
      { events: turn("WAITING_ON_OWNER\nA fresh live acceptance allowance is required.") },
      { events: turn(token) },
    ])
    const runner = launch(t, f)
    await waitFor(
      () =>
        runner.child.exitCode !== null ||
        (existsSync(join(f.state, "status.json")) && state(f).status === "WAITING_ON_OWNER")
    )
    assert.equal(state(f).status, "WAITING_ON_OWNER")
    assert.equal(runner.child.exitCode, null)
    assert.equal(f.calls().length, 1)
    assert.equal(existsSync(join(f.state, "lock")), true)
    await new Promise((resolve) => setTimeout(resolve, 400))
    assert.equal(f.calls().length, 1, "parking must not spend another model turn")
    const runId = state(f).runId
    const resumed = f.resume("The required manual check is complete. Continue the same project.")
    assert.equal(resumed.status, 0, resumed.stderr)
    const result = await runner.exited
    assert.equal(result.code, 0, result.stderr)
    assert.match(result.stdout, /^DONE /m)
    assert.equal(f.calls().length, 2)
    assert.match(f.calls()[1].stdin, /required manual check is complete/)
    assert.equal(state(f).runId, runId)
    assert.equal(state(f).status, "DONE")
  }
)

test(
  "three tool-free replies park even without a marker; owner input survives a failed retry",
  { timeout: 15000 },
  async (t) => {
    const f = fixture(t, [
      ...Array.from({ length: 3 }, () => ({
        events: turn("The manual acceptance gate is still unresolved."),
      })),
      { stderr: "Temporary provider failure", code: 1 },
      { events: turn(token) },
    ])
    const runner = launch(t, f, ["--max-retries", "1"])
    await waitFor(
      () => existsSync(join(f.state, "status.json")) && state(f).status === "WAITING_ON_OWNER"
    )
    assert.equal(f.calls().length, 3)
    assert.match(state(f).message, /Three consecutive turns/)
    assert.equal(f.resume("Manual acceptance completed; continue.").status, 0)
    const result = await runner.exited
    assert.equal(result.code, 0, result.stderr)
    assert.equal(f.calls().length, 5)
    for (const call of f.calls().slice(3)) assert.match(call.stdin, /Manual acceptance completed/)
  }
)

test("completed work tools reset no-progress counting across milestones", (t) => {
  const progress = {
    type: "tool_use",
    sessionID: session,
    part: {
      messageID: "msg_work",
      tool: "bash",
      state: { status: "completed", output: "Milestone verified" },
    },
  }
  const f = fixture(t, [
    { events: turn("Continue") },
    { events: turn("Continue") },
    ...Array.from({ length: 5 }, () => ({
      events: [progress, ...turn("Milestone complete; continuing the project.")],
    })),
    { events: turn("Final review remains") },
    { events: turn(token) },
  ])
  const result = f.run()
  assert.equal(result.status, 0, result.stderr)
  assert.equal(f.calls().length, 9)
})

test(
  "cancellation while parked releases the lock and rejects later resumes",
  { timeout: 15000 },
  async (t) => {
    const f = fixture(t, [{ events: turn("WAITING_ON_OWNER\nManual action required.") }])
    assert.equal(f.resume("Too early").status, 2)
    const runner = launch(t, f)
    await waitFor(
      () => existsSync(join(f.state, "status.json")) && state(f).status === "WAITING_ON_OWNER"
    )
    runner.child.kill("SIGINT")
    assert.equal((await runner.exited).code, 130)
    assert.equal(state(f).status, "CANCELLED")
    assert.equal(existsSync(join(f.state, "lock")), false)
    assert.equal(f.resume("Too late").status, 2)
    assert.equal(f.calls().length, 1)
  }
)

test(
  "resumes bind to one wait and one run, never consuming stale input",
  { timeout: 15000 },
  async (t) => {
    const f = fixture(t, [
      { events: turn("WAITING_ON_OWNER\nFirst manual gate.") },
      { events: turn("WAITING_ON_OWNER\nSecond manual gate.") },
      { events: turn(token) },
    ])
    const runner = launch(t, f)
    await waitFor(
      () => existsSync(join(f.state, "status.json")) && state(f).status === "WAITING_ON_OWNER"
    )
    const first = state(f)
    assert.equal(f.resume("First gate resolved.").status, 0)
    await waitFor(() => state(f).status === "WAITING_ON_OWNER" && state(f).waitId !== first.waitId)
    const second = state(f)
    assert.equal(second.runId, first.runId)
    writeFileSync(
      join(f.state, `resume-${first.waitId}.json`),
      JSON.stringify({
        runId: first.runId,
        waitId: first.waitId,
        prompt: "Stale first-gate input",
      }),
      { mode: 0o600 }
    )
    await new Promise((resolve) => setTimeout(resolve, 400))
    assert.equal(f.calls().length, 2)
    assert.equal(f.resume("Second gate resolved.").status, 0)
    assert.equal((await runner.exited).code, 0)
    assert.match(f.calls()[2].stdin, /Second gate resolved/)
    assert.doesNotMatch(f.calls()[2].stdin, /Stale first-gate input/)
  }
)

test(
  "wrong-run mailbox input fails closed rather than submitting work",
  { timeout: 15000 },
  async (t) => {
    const f = fixture(t, [{ events: turn("WAITING_ON_OWNER\nManual gate.") }])
    const runner = launch(t, f)
    await waitFor(
      () => existsSync(join(f.state, "status.json")) && state(f).status === "WAITING_ON_OWNER"
    )
    const waiting = state(f)
    writeFileSync(
      join(f.state, `resume-${waiting.waitId}.json`),
      JSON.stringify({
        runId: "stale-run",
        waitId: waiting.waitId,
        prompt: "Do not consume",
      }),
      { mode: 0o600 }
    )
    const result = await runner.exited
    assert.equal(result.code, 2)
    assert.match(result.stderr, /Invalid or stale/)
    assert.equal(f.calls().length, 1)
    assert.equal(state(f).status, "BLOCKED")
  }
)

test(
  "native interruption hands control to the owner, attach/status do not resume, and busy handback is rejected",
  { timeout: 15000 },
  async (t) => {
    const f = fixture(t, [
      {
        events: [
          {
            type: "error",
            sessionID: session,
            error: { name: "MessageAbortedError", data: { message: "Aborted" } },
          },
        ],
        code: 1,
      },
      { events: turn(token) },
    ])
    const runner = launch(t, f, ["--max-retries", "unlimited"])
    await waitFor(
      () => existsSync(join(f.state, "status.json")) && state(f).status === "MANUAL_CONTROL"
    )
    const runId = state(f).runId
    assert.equal(f.calls().length, 1)
    for (let i = 0; i < 2; i++) assert.equal(f.command("attach").status, 0)
    const attachments = readFileSync(join(f.root, "attachments.jsonl"), "utf8")
      .trim()
      .split("\n")
      .map(JSON.parse)
    assert.equal(attachments.length, 2)
    for (const attached of attachments) {
      assert.deepEqual(attached.args.slice(-4), ["--dir", f.root, "--session", session])
      assert.equal(statSync(attached.tui).mode & 0o777, 0o600)
    }
    const status = f.command("status", ["--json"])
    assert.equal(status.status, 0, status.stderr)
    assert.equal(JSON.parse(status.stdout).status, "MANUAL_CONTROL")
    assert.doesNotMatch(status.stdout, /password|Authorization/)
    assert.match(f.command("status").stdout, /automatic continuation is paused/)
    await new Promise((resolve) => setTimeout(resolve, 400))
    assert.equal(f.calls().length, 1)
    writeFileSync(join(f.root, "manual-busy"), "yes")
    assert.match(f.resume("Not while busy").stderr, /busy/)
    assert.equal(f.calls().length, 1)
    rmSync(join(f.root, "manual-busy"))
    assert.equal(f.resume("My steering is finished; continue.").status, 0)
    const result = await runner.exited
    assert.equal(result.code, 0, result.stderr)
    assert.equal(state(f).runId, runId)
    assert.match(f.calls()[1].stdin, /My steering is finished/)
  }
)

test(
  "background startup survives launcher exit and detaching clients; explicit stop cleans worker/server state",
  { timeout: 15000 },
  async (t) => {
    const f = fixture(t, [{ events: turn("WAITING_ON_OWNER\nOwner fixture gate.") }])
    const result = spawnSync(
      executable,
      f.args.filter((arg) => arg !== "--foreground"),
      { env: f.env, encoding: "utf8", timeout: 10000 }
    )
    assert.equal(result.status, 0, result.stderr)
    assert.match(result.stdout, /STARTED/)
    await waitFor(() => state(f).status === "WAITING_ON_OWNER")
    const pid = state(f).pid
    assert.doesNotThrow(() => process.kill(pid, 0))
    assert.equal(f.command("attach").status, 0)
    assert.doesNotThrow(() => process.kill(pid, 0))
    assert.equal(f.command("stop").status, 0)
    await waitFor(() => !existsSync(join(f.state, "lock")))
    assert.equal(state(f).status, "CANCELLED")
    assert.equal(
      readdirSync(f.state).some((file) => /^server-.*\.json$/.test(file)),
      false
    )
    assert.equal(f.calls().length, 1)
  }
)

test("the server helper latches native abort fallbacks and stops automatic question replies in manual mode", async (t) => {
  const f = fixture(t, [])
  const controlFile = join(f.root, "control.json")
  writeFileSync(controlFile, JSON.stringify({ runId: "fixture", mode: "automatic" }), {
    mode: 0o600,
  })
  const { default: autonomy } = await import("../scripts/oc-loop-autonomy.mjs")
  let replies = 0
  const hooks = await autonomy(
    {
      directory: f.root,
      client: {
        question: {
          reply: async () => {
            replies++
          },
        },
      },
    },
    { sessionID: session, controlFile, runId: "fixture" }
  )
  const runnerText = "An expected automatic continuation"
  writeFileSync(
    controlFile,
    JSON.stringify({
      runId: "fixture",
      mode: "automatic",
      expectedPrompt: createHash("sha256").update(runnerText).digest("hex"),
    })
  )
  await hooks["chat.message"](
    { sessionID: session },
    { parts: [{ type: "text", text: runnerText }] }
  )
  assert.equal(JSON.parse(readFileSync(controlFile)).mode, "automatic")
  await hooks.event({
    event: {
      type: "message.updated",
      properties: {
        info: { sessionID: session, role: "assistant", error: { name: "MessageAbortedError" } },
      },
    },
  })
  assert.equal(JSON.parse(readFileSync(controlFile)).mode, "manual")
  await hooks.event({
    event: {
      type: "question.asked",
      properties: {
        sessionID: session,
        id: "que_manual",
        questions: [{ options: [{ label: "Must not auto-answer" }] }],
      },
    },
  })
  assert.equal(replies, 0)
  await hooks["chat.message"](
    { sessionID: session },
    { parts: [{ type: "text", text: "Manual steering" }] }
  )
  assert.equal(JSON.parse(readFileSync(controlFile)).mode, "manual")
})

test("status shortcut uses the native TUI command layer without a model request or global config changes", async (t) => {
  const f = fixture(t, [{ events: turn(token) }])
  assert.equal(f.run().status, 0)
  const { default: plugin } = await import("../scripts/oc-loop-tui.mjs")
  let layer, alert, disposed
  await plugin.tui(
    {
      route: { current: { name: "session", params: { sessionID: session } } },
      keymap: {
        registerLayer: (value) => {
          layer = value
          return () => {}
        },
      },
      lifecycle: {
        onDispose: (fn) => {
          disposed = fn
        },
      },
      ui: {
        dialog: { replace: (render) => render() },
        DialogAlert: (value) => {
          alert = value
        },
      },
    },
    { directory: f.root, session, runId: state(f).runId }
  )
  assert.equal(typeof disposed, "function")
  assert.equal(layer.bindings[0].key, "ctrl+f2")
  layer.commands.find((command) => command.name === "oc-loop.status").run()
  assert.match(alert.message, /DONE/)
  assert.equal(f.calls().length, 1)
})

test(
  "a completed owner-approval gate parks even if the attached CLI loses its terminal events",
  { timeout: 15000 },
  async (t) => {
    const gate =
      "Required gate: explicit live-acceptance approval with a fresh submission limit, exact task/data/connection scopes, and an approved current-profile acceptance procedure."
    const f = fixture(t, [{ events: [], persisted: { text: gate } }, { events: turn(token) }])
    const runner = launch(t, f)
    await waitFor(
      () =>
        runner.child.exitCode !== null ||
        (existsSync(join(f.state, "status.json")) && state(f).status === "WAITING_ON_OWNER")
    )
    assert.equal(state(f).status, "WAITING_ON_OWNER")
    assert.equal(f.calls().length, 1)
    assert.match(state(f).message, /fresh submission limit/)
    await new Promise((resolve) => setTimeout(resolve, 400))
    assert.equal(f.calls().length, 1)
    assert.equal(
      f.resume("The approval remains withheld; continue only independent authorized work.").status,
      0
    )
    assert.equal((await runner.exited).code, 0)
  }
)

test(
  "an explicit Required gate response parks even after completed work tools",
  { timeout: 15000 },
  async (t) => {
    const f = fixture(t, [
      {
        events: [
          {
            type: "tool_use",
            sessionID: session,
            part: { messageID: "msg_work", tool: "bash", state: { status: "completed" } },
          },
          ...turn("**Required gate:** explicit live-acceptance approval with exact scopes."),
        ],
      },
      { events: turn(token) },
    ])
    const runner = launch(t, f)
    await waitFor(
      () =>
        runner.child.exitCode !== null ||
        (existsSync(join(f.state, "status.json")) && state(f).status === "WAITING_ON_OWNER")
    )
    assert.equal(state(f).status, "WAITING_ON_OWNER")
    assert.equal(f.calls().length, 1)
    assert.equal(f.resume("Only independently authorized work may continue.").status, 0)
    assert.equal((await runner.exited).code, 0)
  }
)

test("persisted completion tokens and stale owner gates never replace missing terminal events", (t) => {
  for (const persisted of [
    { text: token },
    { text: "Required gate: owner approval", info: { time: { created: 1, completed: 2 } } },
    { text: "Required gate: owner approval", info: { time: { completed: Date.now() } } },
  ]) {
    const f = fixture(t, [{ events: [], persisted }])
    const result = f.run()
    assert.equal(result.status, 2)
    assert.equal(state(f).status, "BLOCKED")
    assert.doesNotMatch(result.stdout, /^DONE/m)
  }
})

test(
  "three missing-terminal failures park instead of spending unlimited retries",
  { timeout: 15000 },
  async (t) => {
    const f = fixture(t, [{ events: [] }, { events: [] }, { events: [] }, { events: turn(token) }])
    const runner = launch(t, f, ["--max-retries", "unlimited"])
    await waitFor(
      () => existsSync(join(f.state, "status.json")) && state(f).status === "WAITING_ON_OWNER"
    )
    assert.equal(f.calls().length, 3)
    assert.match(state(f).message, /without a completed assistant step/)
    assert.equal(f.resume("Transport inspected; retry the same agreed scope.").status, 0)
    assert.equal((await runner.exited).code, 0)
  }
)

test(
  "explicit pause parks the existing worker without restarting its server or session",
  { timeout: 15000 },
  async (t) => {
    const f = fixture(t, [{ wait: true }, { events: turn(token) }])
    const runner = launch(t, f)
    await waitFor(() => existsSync(join(f.root, "child.pid")))
    const runId = state(f).runId
    const paused = f.command("pause")
    assert.equal(paused.status, 0, paused.stderr)
    await waitFor(() => state(f).status === "MANUAL_CONTROL")
    assert.equal(state(f).runId, runId)
    assert.equal(existsSync(join(f.state, "lock")), true)
    assert.equal(f.calls().length, 1)
    assert.equal(f.resume("Continue after explicit pause.").status, 0)
    assert.equal((await runner.exited).code, 0)
  }
)

test("a second runner cannot own the session; Ctrl-C cancels its child and releases the lock", async (t) => {
  const f = fixture(t, [{ wait: true }, { events: turn(token) }])
  const runner = spawn(executable, f.args, { env: f.env, stdio: ["ignore", "pipe", "pipe"] })
  t.after(() => {
    if (runner.exitCode === null) runner.kill("SIGKILL")
  })
  const exited = new Promise((resolve) => runner.once("close", (code) => resolve(code)))
  await waitFor(() => existsSync(join(f.root, "child.pid")))
  const second = f.run()
  assert.equal(second.status, 2, second.stderr)
  assert.match(second.stderr, /locked/i)
  assert.equal(f.calls().length, 1)
  const childPID = Number(readFileSync(join(f.root, "child.pid"), "utf8"))
  runner.kill("SIGINT")
  assert.equal(await exited, 130)
  assert.throws(() => process.kill(childPID, 0), { code: "ESRCH" })
  assert.equal(JSON.parse(readFileSync(join(f.state, "status.json"))).status, "CANCELLED")
  assert.equal(f.run().status, 0)
})

test("a hung turn honors a zero retry budget and its process is terminated", (t) => {
  const f = fixture(t, [{ wait: true }])
  const result = f.run(["--turn-timeout", "1"])
  assert.equal(result.status, 2, result.stderr)
  assert.match(result.stderr, /timed out/i)
  assert.equal(f.calls().length, 1)
  assert.throws(() => process.kill(Number(readFileSync(join(f.root, "child.pid"), "utf8")), 0), {
    code: "ESRCH",
  })
})

test("invalid arguments do not submit work and zero retries also applies to binary/auth failures", (t) => {
  for (const args of [
    ["--session", "ses_../../escape"],
    ["--prompt", ""],
    ["--done-token", "multi\nline"],
    ["--max-retries", "-1"],
    ["--retry-delay", "NaN"],
    ["--turn-timeout", "0"],
    ["--auto"],
    ["--attach", "http://localhost:4096"],
  ]) {
    const f = fixture(t, [])
    assert.equal(f.run(args).status, 2)
    assert.equal(existsSync(join(f.root, "calls.jsonl")), false)
  }
  const missing = fixture(t, [])
  missing.env.OC_LOOP_OPENCODE = join(missing.root, "absent")
  assert.equal(missing.run().status, 2)
  const auth = fixture(t, [{ stderr: "Authentication failed with HTTP 429", code: 1 }])
  assert.equal(auth.run().status, 2)
  assert.equal(auth.calls().length, 1)
})

test("prompt quoting stays literal and ordinary validation tool errors do not prevent later repair", (t) => {
  const f = fixture(t, [
    {
      events: [
        {
          type: "tool_use",
          sessionID: session,
          part: {
            messageID: "msg_test",
            tool: "bash",
            state: { status: "error", error: "permission.test.js: assertion failed" },
          },
        },
        ...turn("Validation failed. Fixing the regression next."),
      ],
    },
    { events: turn(token) },
  ])
  const sentinel = join(f.root, "must-not-exist")
  const text = `Continue 'quoted'; $(touch '${sentinel}'); $HOME stays literal.`
  const result = f.run(["--prompt", text])
  assert.equal(result.status, 0, result.stderr)
  assert.equal(f.calls().length, 2)
  assert.ok(f.calls()[0].stdin.startsWith(text))
  assert.equal(existsSync(sentinel), false)
})

// Explicit provider-free native probe: no model prompt and no real user state.
if (process.env.OC_LOOP_NATIVE_BINARY) {
  test(
    "native persistent server authenticates, loads the run-local helper and exposes the same session without model calls",
    { timeout: 60000 },
    async (t) => {
      const root = realpathSync(mkdtempSync(join(tmpdir(), "oc-loop-server-")))
      t.after(() => rmSync(root, { recursive: true, force: true }))
      const workspace = join(root, "workspace")
      mkdirSync(workspace)
      const home = join(root, "home")
      mkdirSync(join(home, ".config", "opencode"), { recursive: true })
      const environment = {
        HOME: home,
        TMPDIR: root,
        XDG_CONFIG_HOME: join(home, ".config"),
        XDG_DATA_HOME: join(home, ".local", "share"),
        XDG_STATE_HOME: join(home, ".local", "state"),
        XDG_CACHE_HOME: join(home, ".cache"),
        OPENCODE_DISABLE_PROJECT_CONFIG: "1",
        OPENCODE_DISABLE_CLAUDE_CODE: "1",
        OPENCODE_DISABLE_EXTERNAL_SKILLS: "1",
        OPENCODE_DISABLE_CLAUDE_CODE_SKILLS: "1",
        OPENCODE_DISABLE_MODELS_FETCH: "1",
        OPENCODE_DISABLE_DEFAULT_PLUGINS: "1",
        OC_LOOP_OPENCODE: process.env.OC_LOOP_NATIVE_BINARY,
      }
      const baseConfig = { enabled_providers: [], autoupdate: false, snapshot: false, plugin: [] }
      const bootstrapPassword = randomUUID()
      const child = spawn(
        process.env.OC_LOOP_NATIVE_BINARY,
        ["serve", "--hostname", "127.0.0.1", "--port", "0"],
        {
          cwd: workspace,
          env: {
            ...process.env,
            ...environment,
            OPENCODE_CONFIG_CONTENT: JSON.stringify({
              ...baseConfig,
              plugin: [new URL("../scripts/oc-loop-autonomy.mjs", import.meta.url).href],
            }),
            OPENCODE_SERVER_PASSWORD: bootstrapPassword,
            OPENCODE_SERVER_USERNAME: "opencode",
            CI: "true",
          },
          stdio: ["ignore", "pipe", "pipe"],
        }
      )
      let output = "",
        errors = ""
      child.stdout.on("data", (data) => {
        output += data
      })
      child.stderr.on("data", (data) => {
        errors += data
      })
      const closed = new Promise((resolve) => child.once("close", resolve))
      t.after(() => {
        if (child.exitCode === null) child.kill("SIGKILL")
      })
      await waitFor(
        () => /listening on (http:\/\/127\.0\.0\.1:\d+)/.test(output) || child.exitCode !== null
      )
      assert.equal(child.exitCode, null, errors)
      const url = output.match(/listening on (http:\/\/127\.0\.0\.1:\d+)/)[1]
      const created = await fetch(`${url}/session`, {
        method: "POST",
        headers: {
          Authorization: `Basic ${Buffer.from(`opencode:${bootstrapPassword}`).toString("base64")}`,
          "x-opencode-directory": workspace,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ title: "oc-loop provider-free lifecycle fixture" }),
        // Match the runner's cold instance/dependency initialization budget.
        signal: AbortSignal.timeout(30000),
      })
      assert.equal(created.status, 200)
      const nativeSession = await created.json()
      child.kill("SIGTERM")
      await closed
      const { prepare, startServer, request } = await import("../scripts/oc-loop-runtime.mjs")
      const config = { dir: workspace, session: nativeSession.id }
      const { directory } = prepare(config)
      const id = randomUUID()
      const controlFile = join(directory, `control-${id}.json`)
      writeFileSync(controlFile, JSON.stringify({ runId: id, mode: "automatic" }), { mode: 0o600 })
      config.configContent = JSON.stringify({
        ...baseConfig,
        plugin: [
          [
            new URL("../scripts/oc-loop-autonomy.mjs", import.meta.url).href,
            { sessionID: config.session, controlFile, runId: id },
          ],
        ],
      })
      const saved = Object.fromEntries(
        Object.keys(environment).map((key) => [key, process.env[key]])
      )
      Object.assign(process.env, environment)
      let transport
      const nativeLogs = []
      try {
        const state = {
          id,
          record(row) {
            nativeLogs.push(row)
          },
          activity() {},
        }
        transport = await startServer(config, state, new AbortController().signal)
        assert.equal(state.helperReady, true)
        assert.equal(
          (await fetch(`${transport.url}/session`, { signal: AbortSignal.timeout(5000) })).status,
          401
        )
        const credentials = { url: transport.url, password: transport.env.OPENCODE_SERVER_PASSWORD }
        assert.equal(
          (await request(config, credentials, `/session/${config.session}`)).id,
          config.session
        )
        assert.equal(await transport.busy(), false)
        assert.equal(await transport.aborted(), false)
        assert.equal(await transport.ownerGate(Date.now()), undefined)
        assert.equal(statSync(join(directory, `server-${id}.json`)).mode & 0o777, 0o600)
        assert.equal(
          JSON.parse(readFileSync(join(directory, `tui-${id}.json`))).plugin[0][1].runId,
          id
        )
      } catch (error) {
        t.diagnostic(JSON.stringify(nativeLogs.slice(-12)))
        throw error
      } finally {
        if (transport) await transport.close()
        for (const [key, value] of Object.entries(saved)) {
          if (value === undefined) delete process.env[key]
          else process.env[key] = value
        }
      }
      assert.equal(existsSync(join(directory, `server-${id}.json`)), false)
    }
  )

  test("native question tool receives automatic first-option replies through its own SDK transport", (t) => {
    const root = realpathSync(mkdtempSync(join(tmpdir(), "oc-loop-native-")))
    t.after(() => rmSync(root, { recursive: true, force: true }))
    const home = join(root, "home")
    const workspace = join(root, "workspace")
    mkdirSync(workspace)
    mkdirSync(join(home, ".config", "opencode"), { recursive: true })
    const harness = join(root, "native-question.mjs")
    writeFileSync(
      harness,
      `
import autonomy from ${JSON.stringify(new URL("../scripts/oc-loop-autonomy.mjs", import.meta.url).href)}
export default async function (ctx) {
  return { event: async (input) => {
    if (input.event.type !== "question.asked") return
    const hooks = await autonomy(ctx, { sessionID: input.event.properties.sessionID })
    await hooks.event(input)
  } }
}
`
    )
    const env = {
      PATH: process.env.PATH,
      HOME: home,
      TMPDIR: root,
      XDG_CONFIG_HOME: join(home, ".config"),
      XDG_DATA_HOME: join(home, ".local", "share"),
      XDG_STATE_HOME: join(home, ".local", "state"),
      XDG_CACHE_HOME: join(home, ".cache"),
      OPENCODE_DISABLE_PROJECT_CONFIG: "1",
      OPENCODE_DISABLE_CLAUDE_CODE: "1",
      OPENCODE_DISABLE_EXTERNAL_SKILLS: "1",
      OPENCODE_DISABLE_CLAUDE_CODE_SKILLS: "1",
      OPENCODE_DISABLE_MODELS_FETCH: "1",
      OPENCODE_DISABLE_DEFAULT_PLUGINS: "1",
      OPENCODE_CONFIG_CONTENT: JSON.stringify({
        enabled_providers: [],
        autoupdate: false,
        snapshot: false,
        plugin: [pathToFileURL(harness).href],
        agent: {
          fixture: {
            mode: "primary",
            model: "openai/gpt-4o",
            permission: { "*": "deny", question: "allow" },
          },
        },
      }),
      CI: "true",
      GIT_TERMINAL_PROMPT: "0",
    }
    const result = spawnSync(
      process.env.OC_LOOP_NATIVE_BINARY,
      [
        "debug",
        "agent",
        "fixture",
        "--tool",
        "question",
        "--params",
        JSON.stringify({
          questions: [
            {
              header: "Approach",
              question: "Which approach?",
              options: [
                { label: "First", description: "Choose first" },
                { label: "Second", description: "Do not choose second" },
              ],
            },
            {
              header: "Checks",
              question: "Which checks?",
              multiple: true,
              options: [
                { label: "Unit tests", description: "Choose first" },
                { label: "Everything", description: "Do not choose second" },
              ],
            },
          ],
        }),
      ],
      { cwd: workspace, env, encoding: "utf8", timeout: 45000 }
    )
    assert.ifError(result.error)
    assert.equal(result.status, 0, result.stderr)
    const tool = JSON.parse(
      result.stdout
        .split("\n")
        .filter((line) => !line.startsWith('{"type":"oc_loop_autonomy"'))
        .join("\n")
    )
    assert.deepEqual(tool.result.metadata.answers, [["First"], ["Unit tests"]])
    const deniedPath = join(workspace, "must-not-be-created")
    const denied = spawnSync(
      process.env.OC_LOOP_NATIVE_BINARY,
      [
        "debug",
        "agent",
        "fixture",
        "--tool",
        "bash",
        "--params",
        JSON.stringify({ command: `touch '${deniedPath}'`, description: "Denied fixture action" }),
      ],
      { cwd: workspace, env, encoding: "utf8", timeout: 45000 }
    )
    assert.ifError(denied.error)
    assert.equal(denied.status, 1, denied.stderr)
    assert.match(denied.stderr, /Tool bash is disabled/)
    assert.equal(existsSync(deniedPath), false)
  })
}
