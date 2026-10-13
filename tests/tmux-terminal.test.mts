import assert from "node:assert/strict"
import { execFileSync, spawn, spawnSync } from "node:child_process"
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { delimiter, join } from "node:path"
import { fileURLToPath } from "node:url"
import test from "node:test"
import { randomUUID } from "node:crypto"
import { createTerminalContext } from "../modules/home-manager/core/opencode/config/terminal/terminal-context.mts"

function fixture() {
  const root = mkdtempSync(join(tmpdir(), "pane-"))
  const socket = join(root, "tmux")
  const tmux = (...args: string[]) =>
    execFileSync("tmux", ["-S", socket, ...args], {
      encoding: "utf8",
      timeout: 3000,
      env: { ...process.env, TMUX: "", TMUX_PANE: "" },
    }).trim()
  const first = tmux(
    "-f",
    "/dev/null",
    "new-session",
    "-d",
    "-P",
    "-F",
    "#{pane_id}",
    "-s",
    "same-project",
    "sleep 300"
  )
  const second = tmux("split-window", "-d", "-P", "-F", "#{pane_id}", "-t", first, "sleep 300")
  return {
    root,
    socket,
    tmux,
    first,
    second,
    close() {
      try {
        tmux("kill-server")
      } finally {
        rmSync(root, { recursive: true, force: true })
      }
    },
  }
}

test("popup bindings expand caller formats before launching direct helper argv", () => {
  const config = readFileSync(
    new URL("../modules/home-manager/core/tmux/.tmux.conf", import.meta.url),
    "utf8"
  )
  for (const key of ["s", "f", "i"]) {
    const binding = config.split("\n").find((line) => line.startsWith(`bind ${key} `))!
    assert.match(binding, /run-shell -C 'display-popup -c #\{q:client_name\}/)
    assert.match(binding, /--client #\{q:client_name\}/)
    assert.doesNotMatch(binding, /--client "#\{client_name\}"/)
    if (key !== "i") assert.match(binding, /--socket #\{q:socket_path\}/)
  }
})

test("native tree shortcut format expands to one-based keys", () => {
  const f = fixture()
  try {
    const config = readFileSync(
      new URL("../modules/home-manager/core/tmux/.tmux.conf", import.meta.url),
      "utf8"
    )
    const binding = config.split("\n").find((line) => line.startsWith("bind S "))!
    const format = binding.match(/-K '([^']+)'/)![1]
    for (const [line, key] of [
      [0, "1"],
      [8, "9"],
      [9, "0"],
      [10, "M-a"],
    ] as const) {
      assert.equal(f.tmux("display-message", "-p", format.replaceAll("#{line}", String(line))), key)
    }
  } finally {
    f.close()
  }
})

test("notification capture keeps the source pane without selecting it", async () => {
  const f = fixture()
  try {
    const context = createTerminalContext({
      stateDirectory: join(f.root, "state"),
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    const token = await context.capture({
      owner,
      sessionID: "ses_root",
      event: "complete",
      title: "Same project",
      message: "Done",
    })
    const record = context.readEvent(token)
    assert.equal(record.pane, f.second)
    assert.equal(f.tmux("display-message", "-p", "-t", f.first, "#{pane_id}"), f.first)
    assert.equal(f.tmux("display-message", "-p", "-t", f.second, "#{pane_active}"), "0")
    await assert.rejects(context.focus(token), /No eligible Ghostty client/)
    assert.equal(f.tmux("display-message", "-p", "-t", f.second, "#{pane_active}"), "0")
  } finally {
    f.close()
  }
})

test("a mapped notification selects the source even after its pane moves", async () => {
  const f = fixture()
  const nativeCalls: string[][] = []
  try {
    const session = f.tmux("display-message", "-p", "-t", f.second, "#{session_id}")
    const server = f.tmux("display-message", "-p", "-t", f.second, "#{pid}")
    const context = createTerminalContext({
      stateDirectory: join(f.root, "state"),
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
      run(command, args) {
        if (args[0] === "-p" && args[1] === "4321") return "stable-test-client-start"
        if (command === "/usr/bin/osascript") {
          nativeCalls.push(args)
          if (args.includes("ABCDEF00-0000-4000-8000-000000000001")) return ""
          return JSON.stringify({
            surfaces: [
              {
                id: "ABCDEF00-0000-4000-8000-000000000001",
                title: `Useful title [tmux:${server}:4321]`,
              },
            ],
          })
        }
        if (args.includes("list-clients")) return `/dev/ttys999|4321|${session}|xterm-ghostty`
        if (args.includes("switch-client")) return ""
        return execFileSync(command, args, { encoding: "utf8", timeout: 2000 }).trim()
      },
    })
    const owner = await context.register("ses_root")
    const token = await context.capture({
      owner,
      sessionID: "ses_root",
      event: "question",
      title: "Same project",
      message: "Question",
    })
    f.tmux("break-pane", "-d", "-s", f.second, "-n", "renamed")
    const result = await context.focus(token)
    assert.equal(result.pane, f.second)
    assert.equal(result.surface, "ABCDEF00-0000-4000-8000-000000000001")
    assert.equal(
      f.tmux("display-message", "-p", "-t", f.second, "#{pane_active} #{window_active}"),
      "1 1"
    )
    assert.equal(nativeCalls.length, 2)
  } finally {
    f.close()
  }
})

test("replaced launch and restarted server invalidate old notification identities", async () => {
  const f = fixture()
  try {
    const context = createTerminalContext({
      stateDirectory: join(f.root, "state"),
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    const token = await context.capture({ owner, sessionID: "ses_root", event: "complete" })
    await context.register("ses_newroot")
    await assert.rejects(context.focus(token), /Origin pane is stale/)
    f.tmux("set-option", "-g", "@opencode_terminal_server", "00000000-0000-4000-8000-000000000001")
    await assert.rejects(context.focus(token), /tmux server has changed/)
    assert.equal(f.tmux("display-message", "-p", "-t", f.second, "#{pane_active}"), "0")
  } finally {
    f.close()
  }
})

test("notification callback can validate its target with a graphical-session PATH", async () => {
  const f = fixture()
  try {
    const state = join(f.root, "state")
    const context = createTerminalContext({
      stateDirectory: state,
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    const token = await context.capture({ owner, sessionID: "ses_root", event: "complete" })
    const tmuxPath = (process.env.PATH || "")
      .split(delimiter)
      .map((path) => join(path, "tmux"))
      .find((path) => existsSync(path))
    const callback = spawnSync(
      process.execPath,
      [
        fileURLToPath(
          new URL(
            "../modules/home-manager/core/opencode/config/terminal/terminal-context.mts",
            import.meta.url
          )
        ),
        "focus",
        token,
      ],
      {
        env: {
          PATH: "/usr/bin:/bin",
          OPENCODE_TERMINAL_STATE_DIR: state,
          OPENCODE_TERMINAL_TMUX: tmuxPath,
          OPENCODE_TERMINAL_PS: process.env.OPENCODE_TERMINAL_PS || "/bin/ps",
        },
        encoding: "utf8",
        timeout: 5000,
      }
    )
    assert.equal(callback.status, 1)
    assert.match(callback.stderr, /No eligible Ghostty client/)
    assert.doesNotMatch(callback.stderr, /ENOENT/)
  } finally {
    f.close()
  }
})

test("one launch can track multiple roots without remapping its earlier notification", async () => {
  const f = fixture()
  try {
    const context = createTerminalContext({
      stateDirectory: join(f.root, "state"),
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    const first = await context.capture({ owner, sessionID: "ses_root", event: "complete" })
    await assert.rejects(
      context.capture({ owner, sessionID: "ses_child", event: "permission" }),
      /registered root/
    )
    context.addRoot(owner, "ses_second", "Second task")
    const second = await context.capture({ owner, sessionID: "ses_second", event: "question" })
    assert.equal(context.readEvent(first).sessionID, "ses_root")
    assert.equal(context.readEvent(second).sessionID, "ses_second")
    assert.equal(context.readEvent(first).owner, context.readEvent(second).owner)
    await assert.rejects(context.focus(first), /No eligible Ghostty client/)
  } finally {
    f.close()
  }
})

test("attention state stays private, pane headers stay hidden and manual window names survive reload", async () => {
  const f = fixture()
  try {
    const context = createTerminalContext({
      stateDirectory: join(f.root, "state"),
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    const state = context.updateRoot(owner, "ses_root", {
      title: "Fix routing",
      status: "working",
      active: true,
    })
    assert.equal(state.title, "Fix routing")
    assert.equal(state.status, "working")
    assert.equal(f.tmux("show-options", "-pqv", "-t", f.second, "@opencode_terminal_title"), "")
    assert.equal(f.tmux("show-options", "-pqv", "-t", f.first, "@opencode_terminal_title"), "")
    f.tmux("rename-window", "-t", f.first, "Keep my name")
    const config = fileURLToPath(
      new URL("../modules/home-manager/core/tmux/.tmux.conf", import.meta.url)
    )
    f.tmux("source-file", config)
    f.tmux("source-file", config)
    assert.equal(f.tmux("show-options", "-gqv", "pane-border-status"), "off")
    assert.equal(f.tmux("show-options", "-gqv", "pane-border-format"), "")
    assert.equal(
      f.tmux("show-options", "-gwv", "automatic-rename-format"),
      "#{?pane_in_mode,[tmux],#{pane_current_command}}#{?pane_dead,[dead],}"
    )
    assert.equal(f.tmux("display-message", "-p", "-t", f.first, "#{window_name}"), "Keep my name")
    assert.equal(f.tmux("show-options", "-wv", "-t", f.first, "automatic-rename"), "off")
    context.release(owner)
    assert.equal(f.tmux("show-options", "-pqv", "-t", f.second, "@opencode_terminal_title"), "")
  } finally {
    f.close()
  }
})

test("inbox coalesces a root turn, acknowledges completion, and retires resolved questions", async () => {
  const f = fixture()
  try {
    const context = createTerminalContext({
      stateDirectory: join(f.root, "state"),
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    const first = await context.capture({ owner, sessionID: "ses_root", event: "complete" })
    const latest = await context.capture({ owner, sessionID: "ses_root", event: "complete" })
    assert.deepEqual(
      context.listAttention().map((item) => item.token),
      [latest]
    )
    assert.notEqual(first, latest)
    context.ack(latest)
    assert.deepEqual(context.listAttention(), [])
    context.updateRoot(owner, "ses_root", { status: "needs_input" }, true)
    const question = await context.capture({ owner, sessionID: "ses_root", event: "question" })
    assert.equal(context.ack(question), false)
    assert.equal(context.listAttention().length, 1)
    context.updateRoot(owner, "ses_root", { status: "working" })
    assert.equal(context.listAttention().length, 0)
    assert.equal(context.readEvent(question).event, "question")
  } finally {
    f.close()
  }
})

test("expired notifications are pruned without redirecting their tokens", async () => {
  const f = fixture()
  try {
    const state = join(f.root, "state")
    const context = createTerminalContext({
      stateDirectory: state,
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    const token = await context.capture({ owner, sessionID: "ses_root", event: "complete" })
    const path = join(state, `event-${token}.json`)
    const record = JSON.parse(readFileSync(path, "utf8"))
    record.created = Date.now() - 25 * 60 * 60 * 1000
    writeFileSync(path, JSON.stringify(record), { mode: 0o600 })
    context.refresh()
    assert.equal(context.listAttention().length, 0)
    assert.equal(readdirSync(state).filter((name) => name.startsWith("event-")).length, 0)
    await assert.rejects(context.focus(token), /ENOENT/)
  } finally {
    f.close()
  }
})

test("attention history is bounded to 100 immutable event records", async () => {
  const f = fixture()
  try {
    const state = join(f.root, "state")
    const context = createTerminalContext({
      stateDirectory: state,
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    const seed = await context.capture({ owner, sessionID: "ses_root", event: "complete" })
    const record = context.readEvent(seed)
    for (let index = 0; index < 105; index++) {
      const token = randomUUID()
      writeFileSync(
        join(state, `event-${token}.json`),
        JSON.stringify({ ...record, token, created: record.created - 200 + index }),
        { mode: 0o600 }
      )
    }
    context.refresh()
    assert.equal(readdirSync(state).filter((name) => name.startsWith("event-")).length, 100)
    assert.equal(context.readEvent(seed).token, seed)
  } finally {
    f.close()
  }
})

test("deleting a root retires attention without preventing a new conversation in that launch", async () => {
  const f = fixture()
  try {
    const context = createTerminalContext({
      stateDirectory: join(f.root, "state"),
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    context.updateRoot(owner, "ses_root", { title: "Old task", status: "working" })
    const token = await context.capture({ owner, sessionID: "ses_root", event: "complete" })
    context.updateRoot(owner, "ses_root", { status: "idle", deleted: true })
    assert.equal(f.tmux("show-options", "-pqv", "-t", f.second, "@opencode_terminal_title"), "")
    await assert.rejects(context.focus(token), /Root session has been deleted/)
    context.addRoot(owner, "ses_new", "New task")
    const state = context.updateRoot(
      owner,
      "ses_new",
      { title: "New task", status: "working" },
      true
    )
    assert.equal(f.tmux("show-options", "-pqv", "-t", f.second, "@opencode_terminal_title"), "")
    assert.equal(state.title, "New task")
  } finally {
    f.close()
  }
})

test("concurrent deliveries publish complete distinct immutable records", async () => {
  const f = fixture()
  try {
    const state = join(f.root, "state")
    const context = createTerminalContext({
      stateDirectory: state,
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    const moduleURL = new URL(
      "../modules/home-manager/core/opencode/config/terminal/terminal-context.mts",
      import.meta.url
    ).href
    const script = `import { createTerminalContext } from ${JSON.stringify(moduleURL)};
      const context = createTerminalContext({ stateDirectory: process.env.TEST_STATE });
      console.log(await context.capture({ owner: process.env.TEST_OWNER, sessionID: "ses_root", event: "complete" }));`
    const deliver = () =>
      new Promise<string>((resolve, reject) => {
        const child = spawn(process.execPath, ["--input-type=module", "-e", script], {
          env: { ...process.env, TEST_STATE: state, TEST_OWNER: owner },
          timeout: 5000,
        })
        let output = "",
          error = ""
        child.stdout.on("data", (data) => {
          output += data
        })
        child.stderr.on("data", (data) => {
          error += data
        })
        child.on("error", reject)
        child.on("close", (code) =>
          code === 0 ? resolve(output.trim()) : reject(new Error(error))
        )
      })
    const tokens = await Promise.all([deliver(), deliver(), deliver()])
    assert.equal(new Set(tokens).size, 3)
    for (const token of tokens) assert.equal(context.readEvent(token).pane, f.second)
    assert.equal(readdirSync(state).filter((name) => name.startsWith("event-")).length, 3)
  } finally {
    f.close()
  }
})

test("persisted origin fields are decoded before they become typed navigation targets", async () => {
  const f = fixture()
  try {
    const state = join(f.root, "state")
    const context = createTerminalContext({
      stateDirectory: state,
      socket: f.socket,
      pane: f.second,
      processID: Number(f.tmux("display-message", "-p", "-t", f.second, "#{pane_pid}")),
    })
    const owner = await context.register("ses_root")
    const token = await context.capture({ owner, sessionID: "ses_root", event: "complete" })
    const record = context.readEvent(token)
    writeFileSync(
      join(state, `event-${token}.json`),
      JSON.stringify({ ...record, processID: "not-a-pid" }),
      { mode: 0o600 }
    )
    await assert.rejects(context.focus(token), /Invalid origin record/)
    assert.equal(f.tmux("display-message", "-p", "-t", f.second, "#{pane_active}"), "0")
  } finally {
    f.close()
  }
})
