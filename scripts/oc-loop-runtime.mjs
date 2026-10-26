import { spawn } from "node:child_process"
import { randomUUID } from "node:crypto"
import {
  closeSync,
  lstatSync,
  mkdirSync,
  openSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync,
  linkSync,
} from "node:fs"
import { isAbsolute, join } from "node:path"
import { createInterface } from "node:readline"
import { fileURLToPath } from "node:url"
import { setTimeout as sleep } from "node:timers/promises"

export const executable = () => process.env.OC_LOOP_OPENCODE || "opencode"
export const paths = (config) => {
  const agents = join(config.dir, ".agents")
  const base = join(agents, "oc-loop")
  return { agents, base, directory: join(base, config.session) }
}

export function prepare(config) {
  const locations = paths(config)
  for (const path of Object.values(locations)) {
    mkdirSync(path, { recursive: true, mode: 0o700 })
    const stat = lstatSync(path)
    if (!stat.isDirectory() || stat.uid !== process.getuid())
      throw new Error(`Not an owned state directory: ${path}`)
    if (path !== locations.agents && stat.mode & 0o077)
      throw new Error(`State directory is not private: ${path}`)
  }
  return locations
}

export function readOwnedJSON(path) {
  const stat = lstatSync(path)
  if (!stat.isFile() || stat.uid !== process.getuid() || stat.mode & 0o077)
    throw new Error(`Not a private owned state file: ${path}`)
  return JSON.parse(readFileSync(path, "utf8"))
}

export function atomicJSON(path, data) {
  const temporary = `${path}-${randomUUID()}.tmp`
  try {
    writeFileSync(temporary, JSON.stringify(data) + "\n", { flag: "wx", mode: 0o600 })
    renameSync(temporary, path)
  } finally {
    rmSync(temporary, { force: true })
  }
}

export function inspect(config, live = false) {
  const { directory } = prepareExisting(config)
  const status = readOwnedJSON(join(directory, "status.json"))
  if (
    status.session !== config.session ||
    status.directory !== config.dir ||
    !/^[a-f0-9-]{36}$/.test(status.runId ?? "")
  )
    throw new Error("State does not match this project/session")
  if (live) {
    const lock = readOwnedJSON(join(directory, "lock"))
    if (
      lock.runId !== status.runId ||
      lock.pid !== status.pid ||
      !Number.isSafeInteger(status.pid) ||
      status.pid <= 1
    )
      throw new Error("No matching live runner; inspect status and lock")
    process.kill(status.pid, 0)
  }
  return status
}

function prepareExisting(config) {
  const locations = paths(config)
  for (const path of Object.values(locations)) {
    const stat = lstatSync(path)
    if (
      !stat.isDirectory() ||
      stat.uid !== process.getuid() ||
      (path !== locations.agents && stat.mode & 0o077)
    )
      throw new Error(`Not an owned state directory: ${path}`)
  }
  return locations
}

function connection(config, status) {
  const credentials = readOwnedJSON(join(paths(config).directory, `server-${status.runId}.json`))
  if (
    credentials.runId !== status.runId ||
    !/^http:\/\/127\.0\.0\.1:\d+$/.test(credentials.url) ||
    typeof credentials.password !== "string" ||
    (credentials.directory !== undefined &&
      (typeof credentials.directory !== "string" || !isAbsolute(credentials.directory)))
  )
    throw new Error("Invalid local server state")
  return credentials
}

export async function request(config, credentials, route, method = "GET", timeout = 5000) {
  let response
  try {
    response = await fetch(`${credentials.url}${route}`, {
      method,
      headers: {
        Authorization: `Basic ${Buffer.from(`opencode:${credentials.password}`).toString("base64")}`,
        "x-opencode-directory": credentials.directory || config.dir,
      },
      signal: AbortSignal.timeout(timeout),
    })
  } catch (error) {
    throw new Error(`OpenCode ${method} ${route}: ${error.name}`, { cause: error })
  }
  if (!response.ok) throw new Error(`OpenCode ${method} ${route}: HTTP ${response.status}`)
  return response.json()
}

export async function queueResume(config) {
  const status = inspect(config, true)
  if (
    !["WAITING_ON_OWNER", "MANUAL_CONTROL"].includes(status.status) ||
    !/^[a-f0-9-]{36}$/.test(status.waitId ?? "")
  )
    throw new Error("No matching live owner wait")
  const credentials = connection(config, status)
  const sessions = await request(config, credentials, "/session/status")
  if (sessions[config.session] && sessions[config.session].type !== "idle")
    throw new Error(
      "The manually controlled session is busy; finish or interrupt it before resuming"
    )
  const directory = paths(config).directory
  const temporary = join(directory, `resume-${randomUUID()}.tmp`)
  try {
    writeFileSync(
      temporary,
      JSON.stringify({ runId: status.runId, waitId: status.waitId, prompt: config.prompt }),
      { flag: "wx", mode: 0o600 }
    )
    linkSync(temporary, join(directory, `resume-${status.waitId}.json`))
  } finally {
    rmSync(temporary, { force: true })
  }
}

export async function pause(config) {
  const status = inspect(config, true)
  const directory = paths(config).directory
  const controlFile = join(directory, `control-${status.runId}.json`)
  const control = readOwnedJSON(controlFile)
  if (control.runId !== status.runId) throw new Error("Stale runner control state")
  // The one-way latch is understood by already-running workers and their server helper.
  atomicJSON(`${controlFile}.manual`, { runId: status.runId })
  atomicJSON(controlFile, { ...control, mode: "manual", expectedPrompt: undefined })
  const credentials = connection(config, status)
  const sessions = await request(config, credentials, "/session/status")
  if (sessions[config.session] && sessions[config.session].type !== "idle")
    await request(config, credentials, `/session/${config.session}/abort`, "POST")
}

export function summary(status) {
  const age = (time) =>
    time
      ? `${Math.max(0, Math.round((Date.now() - Date.parse(time)) / 1000))}s ago`
      : "not recorded"
  return [
    `${status.status} · ${status.session}`,
    `Project: ${status.directory}`,
    status.nativeDirectory &&
      status.nativeDirectory !== status.directory &&
      `Native session directory: ${status.nativeDirectory}`,
    `Turn: ${status.turn ?? 0} · retries: ${status.retries ?? 0} · started: ${status.startedAt}`,
    `Last activity: ${age(status.lastActivityAt)} · heartbeat: ${age(status.updatedAt)}`,
    status.activity && `Activity: ${status.activity}`,
    status.lastAssistant && `Last assistant: ${status.lastAssistant}`,
    status.message && `Reason: ${status.message}`,
    "Activity is telemetry, not proof of progress or passing checks.",
  ]
    .filter(Boolean)
    .join("\n")
}

export function requiredOwnerGate(text) {
  if (/^WAITING_ON_OWNER(?:\r?\n|$)/.test(text.trim())) return true
  return text.split(/\r?\n/).some((line) => {
    const label = line.replace(/\*\*/g, "").trim()
    return (
      /^Required gate:\s*\S/i.test(label) &&
      /\b(?:approval|approved|authorization|owner|manual|consent|live[- ]acceptance|submission limit)\b/i.test(
        label
      )
    )
  })
}

export async function attach(config) {
  const status = inspect(config, true)
  const credentials = connection(config, status)
  const tuiConfig = join(paths(config).directory, `tui-${status.runId}.json`)
  // Native TUI exits only this client; the worker and server have separate lifetimes.
  const child = spawn(
    executable(),
    [
      "attach",
      credentials.url,
      "--dir",
      credentials.directory || config.dir,
      "--session",
      config.session,
    ],
    {
      cwd: config.dir,
      env: {
        ...process.env,
        OPENCODE_SERVER_USERNAME: "opencode",
        OPENCODE_SERVER_PASSWORD: credentials.password,
        OPENCODE_TUI_CONFIG: tuiConfig,
      },
      stdio: "inherit",
    }
  )
  return await new Promise((resolve, reject) => {
    child.once("error", reject)
    child.once("close", (code) => resolve(code ?? 1))
  })
}

export async function launch(config) {
  const { directory } = prepare(config)
  // Do not mistake an already-running worker's status for our startup acknowledgement.
  try {
    inspect(config, true)
    throw new Error("Session already has a live runner in this project")
  } catch (error) {
    if (error.message.includes("already has")) throw error
    if (error.code !== "ENOENT" && error.code !== "ESRCH") throw error
  }
  const output = join(directory, `worker-${randomUUID()}.log`)
  const fd = openSync(output, "wx", 0o600)
  let child
  try {
    child = spawn(
      process.execPath,
      [
        fileURLToPath(new URL("./oc-loop.mjs", import.meta.url)),
        ...process.argv.slice(2),
        "--foreground",
      ],
      {
        cwd: config.dir,
        detached: true,
        stdio: ["ignore", fd, fd],
        env: process.env,
      }
    )
  } finally {
    closeSync(fd)
  }
  child.unref()
  let spawnError
  child.once("error", (error) => {
    spawnError = error
  })
  const deadline = Date.now() + 45000
  while (Date.now() < deadline) {
    if (spawnError) throw spawnError
    let status
    try {
      status = inspect(config)
    } catch (error) {
      if (error.code !== "ENOENT") throw error
    }
    if (status?.pid === child.pid) {
      if (["BLOCKED", "CANCELLED"].includes(status.status))
        throw new Error(`${status.status}: ${status.message}; see ${output}`)
      if (status.serverReady || status.status === "DONE") {
        process.stdout.write(`STARTED ${config.session}\nState: ${directory}\n`)
        if (process.stdin.isTTY && process.stdout.isTTY && status.status !== "DONE")
          process.exitCode = await attach(config)
        else
          process.stdout.write(
            `Attach: oc-loop attach --dir ${JSON.stringify(config.dir)} --session ${config.session}\n`
          )
        return
      }
    }
    if (child.exitCode !== null || child.signalCode !== null)
      throw new Error(`Worker exited during startup; see ${output}`)
    await sleep(100)
  }
  throw new Error(
    `Worker startup is not confirmed; inspect ${output}. Do not start another loop blindly.`
  )
}

export async function startServer(config, state, signal) {
  const password = randomUUID() + randomUUID()
  const child = spawn(executable(), ["serve", "--hostname", "127.0.0.1", "--port", "0"], {
    cwd: config.dir,
    detached: true,
    stdio: ["ignore", "pipe", "pipe"],
    env: {
      ...process.env,
      CI: "true",
      OPENCODE_CONFIG_CONTENT: config.configContent,
      OPENCODE_SERVER_PASSWORD: password,
      OPENCODE_SERVER_USERNAME: "opencode",
    },
  })
  let url, error
  const exited = new Promise((resolve) => {
    child.once("error", (e) => {
      error = e
      resolve()
    })
    child.once("close", () => {
      error ||= new Error("OpenCode server exited")
      resolve()
    })
  })
  const credentials = { runId: state.id, password }
  const read = async () => {
    for await (const line of createInterface({ input: child.stdout, crlfDelay: Infinity })) {
      // Never record credentials or HTTP authorization headers.
      state.record({ stream: "server", data: line })
      const match = line.match(/^opencode server listening on (http:\/\/127\.0\.0\.1:\d+)$/)
      if (match) url = match[1]
      try {
        const event = JSON.parse(line)
        if (event.type === "oc_loop_autonomy" && event.sessionID === config.session) {
          if (event.status === "ready") state.helperReady = true
          if (event.status === "error") error = new Error(event.message)
          if (event.status === "manual") state.manual = true
          if (event.status === "activity") state.activity(event.activity)
        }
      } catch (e) {
        if (e.name !== "SyntaxError") error = e
      }
    }
  }
  read().catch((e) => {
    error = e
  })
  child.stderr.on("data", (data) =>
    state.record({ stream: "server-stderr", data: data.toString() })
  )
  const kill = (sig) => {
    try {
      if (child.pid) process.kill(-child.pid, sig)
    } catch (e) {
      if (e.code !== "ESRCH") throw e
    }
  }
  const serverFile = join(paths(config).directory, `server-${state.id}.json`)
  const transport = {
    get error() {
      return error
    },
    get url() {
      return url
    },
    get directory() {
      return credentials.directory
    },
    get env() {
      return { OPENCODE_SERVER_PASSWORD: password, OPENCODE_SERVER_USERNAME: "opencode" }
    },
    async busy() {
      const statuses = await request(config, credentials, "/session/status")
      return Boolean(statuses[config.session] && statuses[config.session].type !== "idle")
    },
    async aborted() {
      const messages = await request(
        config,
        credentials,
        `/session/${config.session}/message?limit=1`
      )
      return messages.some(
        (message) =>
          message.info?.role === "assistant" && message.info.error?.name === "MessageAbortedError"
      )
    },
    async ownerGate(since) {
      const messages = await request(
        config,
        credentials,
        `/session/${config.session}/message?limit=2`
      )
      for (const message of messages) {
        const info = message.info
        if (
          info?.role !== "assistant" ||
          info.error ||
          !Number.isFinite(info.time?.created) ||
          !Number.isFinite(info.time?.completed) ||
          info.time.created < since ||
          info.time.completed < info.time.created
        )
          continue
        const text = (message.parts || [])
          .filter((part) => part.type === "text")
          .map((part) => part.text)
          .join("\n")
          .trim()
        if (requiredOwnerGate(text)) return text
      }
    },
    async abort() {
      if (url) await request(config, credentials, `/session/${config.session}/abort`, "POST")
    },
    async close() {
      kill("SIGTERM")
      const timer = setTimeout(() => kill("SIGKILL"), 5000)
      try {
        await exited
      } finally {
        clearTimeout(timer)
        rmSync(serverFile, { force: true })
      }
    },
  }
  try {
    const deadline = Date.now() + 30000
    while (!url) {
      if (error) throw error
      await sleep(50, undefined, { signal })
      if (Date.now() > deadline) throw new Error("Timed out starting the OpenCode server")
    }
    credentials.url = url
    // Initializes this directory's plugin instance and verifies the existing session.
    const session = await request(config, credentials, `/session/${config.session}`, "GET", 30000)
    // Session messages are globally readable, but status/events/permissions belong
    // to the origin instance. Keep project-local state separate from that routing.
    if (session.id !== config.session) throw new Error("OpenCode returned a different session")
    if (typeof session.directory !== "string" || !isAbsolute(session.directory))
      throw new Error("OpenCode returned an invalid native session directory")
    credentials.directory = session.directory
    if (session.directory !== config.dir)
      await request(config, credentials, `/session/${config.session}`, "GET", 30000)
    state.update?.({ nativeDirectory: session.directory })
    const helperDeadline = Date.now() + 5000
    while (!state.helperReady) {
      if (error) throw error
      if (Date.now() > helperDeadline) throw new Error("The automatic question helper did not load")
      await sleep(50, undefined, { signal })
    }
    atomicJSON(serverFile, credentials)
    atomicJSON(join(paths(config).directory, `tui-${state.id}.json`), {
      plugin: [
        [
          new URL("./oc-loop-tui.mjs", import.meta.url).href,
          { directory: config.dir, session: config.session, runId: state.id },
        ],
      ],
    })
    return transport
  } catch (e) {
    await transport.close()
    throw e
  }
}
