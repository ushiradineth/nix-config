import assert from "node:assert/strict"
import { spawn, spawnSync } from "node:child_process"
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
let calls = []
try { calls = readFileSync(root + "/calls.jsonl", "utf8").trim().split("\\n") } catch {}
appendFileSync(root + "/calls.jsonl", JSON.stringify({ args: process.argv.slice(2), stdin: readFileSync(0, "utf8"), config }) + "\\n")
const turns = JSON.parse(readFileSync(root + "/turns.json", "utf8"))
const next = turns[calls.length]
if (!next) { console.error("Unexpected extra turn"); process.exit(99) }
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
    state: join(root, "state", "oc-loop", session),
    run(extra = []) {
      return spawnSync(executable, [...args, "--max-retries", "0", ...extra], {
        env,
        encoding: "utf8",
        timeout: 15000,
      })
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
      "--dir",
      f.root,
      "--session",
      session,
      "--format",
      "json",
      "--auto",
    ])
    assert.match(call.stdin, /Continue the approved project/)
    assert.match(call.stdin, /PROJECT_ENTIRELY_COMPLETE/)
    assert.ok(call.args.includes("--auto"))
  }
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
