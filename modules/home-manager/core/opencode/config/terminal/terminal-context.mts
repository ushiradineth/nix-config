import { execFileSync, spawnSync } from "node:child_process"
import { randomUUID } from "node:crypto"
import {
  closeSync,
  constants,
  fstatSync,
  linkSync,
  lstatSync,
  mkdirSync,
  openSync,
  readFileSync,
  readdirSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs"
import { homedir } from "node:os"
import { basename, isAbsolute, join, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import type { Readable, Writable } from "node:stream"

type InboxInput = Readable & {
  isTTY?: boolean
  isRaw?: boolean
  setRawMode?: (mode: boolean) => unknown
}

export async function inboxMessage(
  message: string,
  input: InboxInput = process.stdin,
  output: Writable = process.stdout
): Promise<void> {
  output.write(`${message}\n`)
  if (!input.isTTY || !input.setRawMode) return
  output.write("\nPress Enter or Esc to close.\n")
  const wasRaw = input.isRaw ?? false
  const setRawMode = input.setRawMode.bind(input)
  setRawMode(true)
  input.resume()
  try {
    await new Promise<void>((resolve) => {
      const finish = () => {
        input.off("data", onData)
        input.off("end", finish)
        input.off("close", finish)
        resolve()
      }
      const onData = (data: Buffer | string) => {
        const bytes = Buffer.isBuffer(data) ? data : Buffer.from(data)
        if ([3, 10, 13, 27].some((key) => bytes.includes(key))) finish()
      }
      input.on("data", onData)
      input.once("end", finish)
      input.once("close", finish)
    })
  } finally {
    setRawMode(wasRaw)
    input.pause()
  }
}

export type RootStatus = "idle" | "working" | "needs_input" | "done" | "error"
export type AttentionEvent = "permission" | "question" | "complete" | "error" | "plan_exit"

export interface RootState {
  id: string
  title: string
  status: RootStatus
  pending: string[]
  active?: boolean
  cancelled?: boolean
  deleted?: boolean
}

export interface TerminalEvent {
  type: string
  properties?: {
    info?: { id?: string; parentID?: string | null; title?: string }
    sessionID?: string
    id?: string
    requestID?: string
    status?: { type?: string }
    error?: { name?: string }
  }
}

type RunCommand = (command: string, args: string[]) => string
interface ContextOptions {
  env?: NodeJS.ProcessEnv
  run?: RunCommand
  socket?: string
  pane?: string
  processID?: number
  stateDirectory?: string
  directory?: string
}

interface TmuxClient {
  name: string
  pid: number
  session: string
  term: string
  activePane?: string
  start?: string
}

interface Origin {
  socket: string
  pane: string
  server: string
  processID: number
  processStart: string
  panePID: number
  paneStart: string
  session: string
  sessionID: string
  project: string
  client: TmuxClient | null
  created: number
}

type RecordKind = "owner" | "event" | "ack" | `root-${string}`
interface BaseRecord {
  version: 1
  kind: RecordKind
  token: string
}
interface OwnerRecord extends Origin, BaseRecord {
  kind: "owner"
}
interface EventRecord extends Origin, BaseRecord {
  kind: "event"
  owner: string
  generation: number
  event: AttentionEvent
  title: string
  message: string
}
interface RootRecord extends Omit<RootState, "id">, BaseRecord {
  kind: `root-${string}`
  id?: string
  sessionID: string
  generation: number
  updated: number
}
interface AckRecord extends BaseRecord {
  kind: "ack"
  created: number
}
type RecordFor<K extends RecordKind> = K extends "owner"
  ? OwnerRecord
  : K extends "event"
    ? EventRecord
    : K extends "ack"
      ? AckRecord
      : RootRecord

interface CaptureInput {
  owner: string
  sessionID: string
  event: AttentionEvent
  title?: string
  message?: string
}

interface GhosttyState {
  surfaces: { id: string; title: string }[]
  focused?: string | null
  frontmost?: boolean
}

function errorCode(error: unknown): string | undefined {
  return error instanceof Error && "code" in error && typeof error.code === "string"
    ? error.code
    : undefined
}

function object(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value)
}

function decodeRecord<K extends RecordKind>(value: unknown, kind: K, token: string): RecordFor<K> {
  if (!object(value) || value.version !== 1 || value.token !== token || value.kind !== kind) {
    throw new Error("Invalid state record")
  }
  const strings = (keys: string[]) => keys.every((key) => typeof value[key] === "string")
  const numbers = (keys: string[]) =>
    keys.every((key) => typeof value[key] === "number" && Number.isFinite(value[key]))
  if (kind === "owner" || kind === "event") {
    if (
      !strings([
        "socket",
        "pane",
        "server",
        "processStart",
        "paneStart",
        "session",
        "sessionID",
        "project",
      ]) ||
      !numbers(["processID", "panePID", "created"])
    )
      throw new Error("Invalid origin record")
    const client = value.client
    if (
      client !== null &&
      (!object(client) ||
        typeof client.name !== "string" ||
        typeof client.pid !== "number" ||
        typeof client.session !== "string" ||
        typeof client.term !== "string" ||
        (client.start !== undefined && typeof client.start !== "string") ||
        (client.activePane !== undefined && typeof client.activePane !== "string"))
    )
      throw new Error("Invalid client record")
    if (
      kind === "event" &&
      (!strings(["owner", "title", "message", "event"]) ||
        !numbers(["generation"]) ||
        !EVENTS.has(value.event as AttentionEvent))
    )
      throw new Error("Invalid attention record")
  } else if (kind === "ack") {
    if (!numbers(["created"])) throw new Error("Invalid acknowledgement record")
  } else {
    if (
      !strings(["sessionID", "title", "status"]) ||
      !numbers(["generation", "updated"]) ||
      !["idle", "working", "needs_input", "done", "error"].includes(value.status as string) ||
      !Array.isArray(value.pending) ||
      !value.pending.every((item) => typeof item === "string") ||
      ["active", "cancelled", "deleted"].some(
        (key) => value[key] !== undefined && typeof value[key] !== "boolean"
      )
    ) {
      throw new Error("Invalid root record")
    }
  }
  return value as unknown as RecordFor<K>
}

function decodeGhostty(value: unknown): GhosttyState {
  if (
    !object(value) ||
    !Array.isArray(value.surfaces) ||
    !value.surfaces.every(
      (surface) =>
        object(surface) && typeof surface.id === "string" && typeof surface.title === "string"
    ) ||
    (value.frontmost !== undefined && typeof value.frontmost !== "boolean") ||
    (value.focused !== undefined && value.focused !== null && typeof value.focused !== "string")
  ) {
    throw new Error("Invalid Ghostty response")
  }
  return value as unknown as GhosttyState
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
const SESSION = /^ses_[a-zA-Z0-9]+$/
const EVENTS = new Set(["permission", "question", "complete", "error", "plan_exit"])
const MAX_AGE = 24 * 60 * 60 * 1000
const OWNER_OPTION = "@opencode_terminal_owner"
const SERVER_OPTION = "@opencode_terminal_server"
const LEGACY_PANE_OPTIONS = [
  "@opencode_terminal_title",
  "@opencode_terminal_status",
  "@opencode_terminal_session",
]

const GHOSTTY_QUERY = `
const app = Application("Ghostty");
if (!app.running()) {
  JSON.stringify({surfaces: [], focused: null, frontmost: false});
} else {
const surfaces = app.terminals().map(t => ({id: t.id(), title: t.name()}));
let focused = null;
try { focused = app.frontWindow().selectedTab().focusedTerminal().id(); } catch (_) {}
JSON.stringify({surfaces, focused, frontmost: app.frontmost()});
}`
const GHOSTTY_FOCUS = `
function run(argv) {
  const app = Application("Ghostty");
  if (!app.running()) throw new Error("Ghostty exited");
  app.focus(app.terminals.byId(argv[0]));
}`

export function cleanText(value: unknown, limit = 160): string {
  if (typeof value !== "string") return ""
  const withoutANSI = value.replace(
    new RegExp(`${String.fromCharCode(27)}\\[[0-?]*[ -/]*[@-~]`, "g"),
    ""
  )
  return Array.from(withoutANSI)
    .filter((character) => {
      const code = character.codePointAt(0) ?? 0
      return code >= 32 && (code < 127 || code > 159) && character !== "#"
    })
    .join("")
    .slice(0, limit)
}

function socketFromEnvironment(env: NodeJS.ProcessEnv): string {
  const value = env.TMUX
  if (!value) return ""
  const end = value.lastIndexOf(",")
  const previous = end > 0 ? value.lastIndexOf(",", end - 1) : -1
  return previous > 0 ? value.slice(0, previous) : ""
}

function execute(command: string, args: string[]): string {
  return execFileSync(command, args, {
    encoding: "utf8",
    timeout: 2000,
    maxBuffer: 256 * 1024,
    stdio: ["ignore", "pipe", "pipe"],
    env: { ...process.env, LC_ALL: "C" },
  }).trim()
}

export function rootTransition(root: RootState, event: TerminalEvent): RootState {
  if (
    ![
      "session.updated",
      "permission.asked",
      "question.asked",
      "permission.replied",
      "question.replied",
      "question.rejected",
      "session.status",
      "session.idle",
      "session.error",
      "session.deleted",
    ].includes(event.type)
  )
    return root
  const properties = event.properties ?? {}
  const id = properties.info?.id ?? properties.sessionID
  if (id !== root.id || properties.info?.parentID) return root
  const next: RootState = { ...root, pending: [...(root.pending ?? [])] }
  if (event.type === "session.updated") next.title = cleanText(properties.info?.title)
  if (event.type === "permission.asked" || event.type === "question.asked") {
    if (properties.id && !next.pending.includes(properties.id)) next.pending.push(properties.id)
    next.status = "needs_input"
  }
  if (["permission.replied", "question.replied", "question.rejected"].includes(event.type)) {
    next.pending = next.pending.filter((id) => id !== properties.requestID)
    next.status = next.pending.length ? "needs_input" : "working"
  }
  if (event.type === "session.status" && properties.status?.type !== "idle") {
    next.status = next.pending.length ? "needs_input" : "working"
  }
  if (event.type === "session.idle")
    next.status = next.pending.length
      ? "needs_input"
      : root.cancelled
        ? "idle"
        : root.status === "error"
          ? "error"
          : "done"
  if (event.type === "session.error") {
    next.cancelled = properties.error?.name === "MessageAbortedError"
    next.status = next.cancelled ? "idle" : "error"
    next.pending = []
  }
  if (event.type === "session.deleted") {
    next.status = "idle"
    next.pending = []
    next.deleted = true
  }
  if (
    next.title === root.title &&
    next.status === root.status &&
    next.deleted === root.deleted &&
    next.cancelled === root.cancelled &&
    next.pending.length === (root.pending ?? []).length &&
    next.pending.every((id, index) => id === root.pending[index])
  )
    return root
  return next
}

export function createTerminalContext(options: ContextOptions = {}) {
  const env = options.env ?? process.env
  const run = options.run ?? execute
  const socket = options.socket ?? socketFromEnvironment(env)
  const pane = options.pane ?? env.TMUX_PANE ?? ""
  const processID = options.processID ?? process.pid
  const stateDirectory =
    options.stateDirectory ??
    env.OPENCODE_TERMINAL_STATE_DIR ??
    join(env.XDG_STATE_HOME || join(homedir(), ".local", "state"), "opencode-terminal")
  const tmuxPath = env.OPENCODE_TERMINAL_TMUX || "tmux"
  const psPath = env.OPENCODE_TERMINAL_PS || (process.platform === "darwin" ? "/bin/ps" : "ps")
  if (!process.getuid) throw new Error("This tool requires a Unix user identity")
  const uid = process.getuid()

  function directory() {
    if (!isAbsolute(stateDirectory)) throw new Error("State directory must be absolute")
    try {
      lstatSync(stateDirectory)
    } catch (error) {
      if (errorCode(error) !== "ENOENT") throw error
      mkdirSync(stateDirectory, { recursive: true, mode: 0o700 })
    }
    const info = lstatSync(stateDirectory)
    if (!info.isDirectory() || info.isSymbolicLink() || info.uid !== uid || info.mode & 0o077) {
      throw new Error("Unsafe state directory")
    }
  }

  function read<K extends RecordKind>(kind: K, token: string): RecordFor<K> {
    if (!UUID.test(token)) throw new Error("Invalid notification token")
    directory()
    const fd = openSync(
      join(stateDirectory, `${kind}-${token}.json`),
      constants.O_RDONLY | constants.O_NOFOLLOW
    )
    try {
      const info = fstatSync(fd)
      if (
        !info.isFile() ||
        info.uid !== uid ||
        info.mode & 0o077 ||
        info.size > 8192 ||
        info.nlink !== 1
      ) {
        throw new Error("Unsafe state record")
      }
      const record: unknown = JSON.parse(readFileSync(fd, "utf8"))
      return decodeRecord(record, kind, token)
    } finally {
      closeSync(fd)
    }
  }

  function write<K extends RecordKind>(
    kind: K,
    token: string,
    data: Omit<RecordFor<K>, keyof BaseRecord>,
    replace = false
  ) {
    directory()
    const temporary = join(stateDirectory, `.${randomUUID()}.tmp`)
    const target = join(stateDirectory, `${kind}-${token}.json`)
    if (replace) {
      try {
        read(kind, token)
      } catch (error) {
        if (errorCode(error) !== "ENOENT") throw error
      }
    }
    const fd = openSync(
      temporary,
      constants.O_WRONLY | constants.O_CREAT | constants.O_EXCL | constants.O_NOFOLLOW,
      0o600
    )
    try {
      writeFileSync(fd, JSON.stringify({ ...data, version: 1, kind, token }))
      // Linking publishes a complete record without overwriting an existing token.
      if (replace) renameSync(temporary, target)
      else linkSync(temporary, target)
    } finally {
      closeSync(fd)
      rmSync(temporary, { force: true })
    }
  }

  function tmuxAt(targetSocket: string, ...args: string[]): string {
    if (
      !isAbsolute(targetSocket) ||
      Array.from(targetSocket).some((character) => (character.codePointAt(0) ?? 0) < 32)
    ) {
      throw new Error("Invalid tmux socket")
    }
    return run(tmuxPath, ["-S", targetSocket, ...args])
  }

  function processStart(pid: number): string {
    if (!Number.isSafeInteger(pid) || pid < 1) throw new Error("Invalid process identity")
    const value = run(psPath, ["-p", String(pid), "-o", "lstart="])
    if (!value) throw new Error("Origin process has exited")
    return value
  }

  function locations(targetSocket: string, targetPane: string) {
    if (!/^%\d+$/.test(targetPane)) throw new Error("Invalid pane identity")
    return tmuxAt(
      targetSocket,
      "list-panes",
      "-a",
      "-F",
      `#{pane_id}|#{pane_pid}|#{session_id}|#{window_id}|#{window_zoomed_flag}|#{${OWNER_OPTION}}`
    )
      .split("\n")
      .map((line) => {
        const [id, pid, session, window, zoomed, owner] = line.split("|")
        return { pane: id, panePID: Number(pid), session, window, zoomed: zoomed === "1", owner }
      })
      .filter((item) => item.pane === targetPane)
  }

  function clients(targetSocket: string): TmuxClient[] {
    const output = tmuxAt(
      targetSocket,
      "list-clients",
      "-F",
      "#{client_name}|#{client_pid}|#{session_id}|#{client_termname}|#{pane_id}"
    )
    return output
      .split("\n")
      .filter(Boolean)
      .map((line) => {
        const [name, pid, session, term, activePane] = line.split("|")
        return { name, pid: Number(pid), session, term, activePane }
      })
      .filter(
        (client) =>
          /^\/dev\/[a-zA-Z0-9/]+$/.test(client.name) &&
          Number.isSafeInteger(client.pid) &&
          /ghostty/.test(client.term)
      )
  }

  function validate(record: Origin & { owner: string }, requireRoot = true) {
    if (
      !UUID.test(record.owner) ||
      !UUID.test(record.server) ||
      !SESSION.test(record.sessionID) ||
      !Number.isFinite(record.created) ||
      Date.now() - record.created > MAX_AGE ||
      record.created > Date.now() + 1000
    ) {
      throw new Error("Notification is stale or invalid")
    }
    const owner = read("owner", record.owner)
    for (const key of [
      "socket",
      "pane",
      "server",
      "processID",
      "processStart",
      "panePID",
      "paneStart",
    ] as const) {
      if (owner[key] !== record[key]) throw new Error("Origin registration has changed")
    }
    if (
      tmuxAt(record.socket, "show-options", "-gqv", SERVER_OPTION) !== record.server ||
      processStart(record.processID) !== record.processStart ||
      processStart(record.panePID) !== record.paneStart
    ) {
      throw new Error("Origin process or tmux server has changed")
    }
    const places = locations(record.socket, record.pane).filter(
      (item) => item.owner === record.owner && item.panePID === record.panePID
    )
    const location =
      places.find((item) => item.session === record.session) ??
      (places.length === 1 ? places[0] : undefined)
    if (!location) throw new Error("Origin pane is stale or ambiguous")
    if (requireRoot && rootRecord(record.owner, record.sessionID).deleted)
      throw new Error("Root session has been deleted")
    return location
  }

  function rootRecord(owner: string, sessionID: string): RootRecord {
    if (!SESSION.test(sessionID)) throw new Error("Invalid root session ID")
    return read(`root-${sessionID}`, owner)
  }

  function updateRoot(
    ownerToken: string,
    sessionID: string,
    changes: Partial<RootState>,
    newTurn = false
  ): RootRecord {
    const owner = read("owner", ownerToken)
    validate({ ...owner, owner: ownerToken, sessionID, created: Date.now() })
    const root = rootRecord(ownerToken, sessionID)
    const next = {
      ...root,
      ...changes,
      title: cleanText(changes.title ?? root.title),
      updated: Date.now(),
      generation: root.generation + (newTurn ? 1 : 0),
    }
    if (!["idle", "working", "needs_input", "done", "error"].includes(next.status))
      throw new Error("Invalid root state")
    write(`root-${sessionID}`, ownerToken, next, true)
    updateCount(owner.socket)
    return next
  }

  function events(): EventRecord[] {
    directory()
    return readdirSync(stateDirectory)
      .flatMap((name) => {
        const match = /^event-([0-9a-f-]{36})\.json$/.exec(name)
        if (!match) return []
        try {
          return [read("event", match[1])]
        } catch {
          return []
        }
      })
      .sort((a, b) => b.created - a.created || b.token.localeCompare(a.token))
  }

  function listAttention(targetSocket = socket) {
    const latest = new Map<string, EventRecord>()
    for (const record of events()) {
      if (record.socket !== targetSocket || Date.now() - record.created > MAX_AGE) continue
      const key = `${record.owner}:${record.sessionID}:${record.generation}`
      if (!latest.has(key)) latest.set(key, record)
    }
    return Array.from(latest.values())
      .filter((record) => {
        try {
          const root = rootRecord(record.owner, record.sessionID)
          if (root.generation !== record.generation || root.deleted) return false
          if (["permission", "question"].includes(record.event) && root.status !== "needs_input")
            return false
          if (["complete", "error"].includes(record.event) && root.status === "working")
            return false
          try {
            read("ack", record.token)
            return false
          } catch (error) {
            if (errorCode(error) !== "ENOENT") return false
          }
          validate(record)
          return true
        } catch {
          return false
        }
      })
      .sort((a, b) => a.created - b.created || a.token.localeCompare(b.token))
  }

  function updateCount(targetSocket: string): number {
    const count = listAttention(targetSocket).length
    tmuxAt(targetSocket, "set-option", "-g", "@opencode_terminal_attention", String(count))
    return count
  }

  function prune(keepToken?: string) {
    let retained = keepToken ? 1 : 0
    for (const record of events()) {
      if (record.token === keepToken) continue
      if (Date.now() - record.created > MAX_AGE || retained >= 100) {
        rmSync(join(stateDirectory, `event-${record.token}.json`), { force: true })
        rmSync(join(stateDirectory, `ack-${record.token}.json`), { force: true })
      } else retained++
    }
  }

  function ack(token: string, dismiss = false): boolean {
    const record = read("event", token)
    validate(record)
    if (["permission", "question"].includes(record.event) && !dismiss) return false
    write("ack", token, { created: Date.now() }, true)
    updateCount(record.socket)
    return true
  }

  function release(token: string) {
    const owner = read("owner", token)
    if (!/^%\d+$/.test(owner.pane)) throw new Error("Invalid pane identity")
    const commands = [...LEGACY_PANE_OPTIONS, OWNER_OPTION]
      .map((key) => `set-option -pu -t ${owner.pane} ${key}`)
      .join(" ; ")
    tmuxAt(
      owner.socket,
      "if-shell",
      "-F",
      "-t",
      owner.pane,
      `#{==:#{${OWNER_OPTION}},${token}}`,
      commands
    )
  }

  function refresh() {
    directory()
    for (const name of readdirSync(stateDirectory)) {
      const match = /^owner-([0-9a-f-]{36})\.json$/.exec(name)
      if (!match) continue
      let owner: OwnerRecord
      try {
        owner = read("owner", match[1])
      } catch {
        continue
      }
      if (owner.socket !== socket) continue
      try {
        validate({ ...owner, owner: owner.token, created: Date.now() }, false)
      } catch {
        try {
          release(owner.token)
        } catch {}
        for (const file of readdirSync(stateDirectory)) {
          if (
            file === name ||
            (file.startsWith("root-ses_") && file.endsWith(`-${owner.token}.json`))
          ) {
            rmSync(join(stateDirectory, file), { force: true })
          }
        }
      }
    }
    prune()
    return socket ? updateCount(socket) : 0
  }

  return {
    ownedTUI() {
      if (
        env.SSH_CONNECTION ||
        env.SSH_TTY ||
        (env.OPENCODE_CLIENT && env.OPENCODE_CLIENT !== "cli")
      )
        return false
      try {
        const command = run(psPath, ["-p", String(processID), "-o", "args="])
        const words = command.split(/\s+/)
        if (!/(^|\/)\.?opencode(?:-wrapped)?$/.test(words[0])) return false
        if (
          words
            .slice(1)
            .some(
              (word) =>
                [
                  "run",
                  "serve",
                  "web",
                  "acp",
                  "attach",
                  "debug",
                  "auth",
                  "mcp",
                  "agent",
                  "export",
                  "import",
                  "session",
                  "models",
                  "stats",
                  "upgrade",
                  "uninstall",
                  "github",
                  "pr",
                  "completion",
                  "--help",
                  "-h",
                  "--version",
                  "--mini",
                  "--port",
                  "--hostname",
                  "--mdns",
                ].includes(word) || /^(--port|--hostname|--mdns)=/.test(word)
            )
        )
          return false
        const targetTTY = tmuxAt(socket, "display-message", "-p", "-t", pane, "#{pane_tty}")
        const processTTY = run(psPath, ["-p", String(processID), "-o", "tty="])
        if (targetTTY !== `/dev/${processTTY}`) return false
        const leader = locations(socket, pane)[0]?.panePID
        let ancestor = processID
        for (let depth = 0; ancestor > 1 && depth < 16; depth++) {
          if (ancestor === leader) return true
          ancestor = Number(run(psPath, ["-p", String(ancestor), "-o", "ppid="]))
        }
      } catch {}
      return false
    },
    initialRoot() {
      const words = run(psPath, ["-p", String(processID), "-o", "args="]).split(/\s+/)
      for (let index = 1; index < words.length; index++) {
        const candidate = ["-s", "--session"].includes(words[index])
          ? words[index + 1]
          : words[index].startsWith("--session=")
            ? words[index].slice(10)
            : undefined
        if (SESSION.test(candidate ?? "")) return candidate
      }
    },
    async register(sessionID: string): Promise<string> {
      if (!SESSION.test(sessionID)) throw new Error("Root session ID is required")
      const places = locations(socket, pane)
      if (places.length !== 1) throw new Error("Origin pane is ambiguous")
      const location = places[0]
      const token = randomUUID()
      try {
        tmuxAt(socket, "set-option", "-go", SERVER_OPTION, randomUUID())
      } catch {
        // -o refuses an already registered server; read its existing identity below.
      }
      const server = tmuxAt(socket, "show-options", "-gqv", SERVER_OPTION)
      if (!UUID.test(server)) throw new Error("Missing server identity")
      const originClients = clients(socket).filter((client) => client.session === location.session)
      write("owner", token, {
        socket,
        pane,
        server,
        processID,
        processStart: processStart(processID),
        panePID: location.panePID,
        paneStart: processStart(location.panePID),
        session: location.session,
        sessionID,
        project: cleanText(
          basename(
            options.directory ||
              tmuxAt(socket, "display-message", "-p", "-t", pane, "#{pane_current_path}")
          ),
          80
        ),
        client:
          originClients.length === 1
            ? { ...originClients[0], start: processStart(originClients[0].pid) }
            : null,
        created: Date.now(),
      })
      tmuxAt(socket, "set-option", "-p", "-t", pane, OWNER_OPTION, token)
      write(`root-${sessionID}`, token, {
        sessionID,
        title: "",
        status: "idle",
        pending: [],
        generation: 0,
        updated: Date.now(),
      })
      return token
    },
    addRoot(token: string, sessionID: string, title?: string): RootRecord {
      const owner = read("owner", token)
      validate({ ...owner, owner: token, created: Date.now() }, false)
      if (!SESSION.test(sessionID)) throw new Error("Invalid root session ID")
      try {
        return rootRecord(token, sessionID)
      } catch (error) {
        if (errorCode(error) !== "ENOENT") throw error
      }
      write(`root-${sessionID}`, token, {
        sessionID,
        title: cleanText(title),
        status: "idle",
        pending: [],
        generation: 0,
        updated: Date.now(),
      })
      return rootRecord(token, sessionID)
    },
    updateRoot,
    release,
    listAttention,
    ack,
    refresh,
    async capture({
      owner: token,
      sessionID,
      event,
      title,
      message,
    }: CaptureInput): Promise<string> {
      if (!EVENTS.has(event)) throw new Error("Unsupported attention event")
      const owner = read("owner", token)
      let root: RootRecord
      try {
        root = rootRecord(token, sessionID)
      } catch {
        throw new Error("Event does not belong to a registered root")
      }
      validate({ ...owner, owner: token, sessionID, created: Date.now() })
      if (root.deleted) throw new Error("Root session has been deleted")
      const eventToken = randomUUID()
      write("event", eventToken, {
        ...owner,
        owner: token,
        sessionID,
        generation: root.generation,
        created: Date.now(),
        event,
        title: cleanText(title || root.title),
        message: cleanText(message, 320),
      })
      prune(eventToken)
      updateCount(owner.socket)
      return eventToken
    },
    readEvent(token: string): EventRecord {
      return read("event", token)
    },
    async focus(token: string, { client: caller }: { client?: string } = {}) {
      if (!UUID.test(token)) throw new Error("Invalid notification token")
      const record = read("event", token)
      let location = validate(record)
      const eligible = clients(record.socket)
      if (!eligible.length) throw new Error("No eligible Ghostty client")
      let client: TmuxClient | undefined, surface: string | undefined
      if (caller) {
        client = eligible.find((item) => item.name === caller)
        if (!client) throw new Error("Calling client is unavailable")
      } else {
        const serverPID = tmuxAt(record.socket, "display-message", "-p", "#{pid}")
        if (!/^\d+$/.test(serverPID)) throw new Error("Invalid server process")
        const native = decodeGhostty(
          JSON.parse(run("/usr/bin/osascript", ["-l", "JavaScript", "-e", GHOSTTY_QUERY]))
        )
        const mapped = eligible.flatMap((item) => {
          const suffix = `[tmux:${serverPID}:${item.pid}]`
          const matches = native.surfaces.filter(
            (candidate) => typeof candidate.title === "string" && candidate.title.endsWith(suffix)
          )
          return matches.length === 1 && /^[0-9A-Fa-f-]{36}$/.test(matches[0].id)
            ? [{ client: item, surface: matches[0].id }]
            : []
        })
        const match =
          mapped.find(
            (item) =>
              record.client?.pid === item.client.pid &&
              record.client.name === item.client.name &&
              (!record.client.start || record.client.start === processStart(item.client.pid))
          ) ?? (mapped.length === 1 ? mapped[0] : undefined)
        if (!match) throw new Error("Ghostty surface mapping is missing or ambiguous")
        ;({ client, surface } = match)
      }
      // Revalidate after native lookup, before any selection.
      if (!client) throw new Error("Target client is unavailable")
      const targetClient = client
      location = validate(record)
      if (
        !clients(record.socket).some(
          (item) => item.name === targetClient.name && item.pid === targetClient.pid
        )
      )
        throw new Error("Target client detached")
      tmuxAt(record.socket, "switch-client", "-c", client.name, "-t", location.session)
      tmuxAt(record.socket, "select-window", "-t", `${location.session}:${location.window}`)
      if (location.zoomed) tmuxAt(record.socket, "resize-pane", "-Z", "-t", record.pane)
      tmuxAt(record.socket, "select-pane", "-t", record.pane)
      if (surface) run("/usr/bin/osascript", ["-l", "JavaScript", "-e", GHOSTTY_FOCUS, surface])
      ack(token)
      return { pane: record.pane, client: client.name, surface }
    },
    async notify(token: string) {
      const record = read("event", token)
      validate(record)
      try {
        const native = decodeGhostty(
          JSON.parse(run("/usr/bin/osascript", ["-l", "JavaScript", "-e", GHOSTTY_QUERY]))
        )
        const serverPID = tmuxAt(record.socket, "display-message", "-p", "#{pid}")
        if (
          native.frontmost &&
          clients(record.socket).some(
            (client) =>
              client.activePane === record.pane &&
              native.surfaces.some(
                (surface) =>
                  surface.id === native.focused &&
                  surface.title.endsWith(`[tmux:${serverPID}:${client.pid}]`)
              )
          )
        )
          return
      } catch {
        /* Unknown focus must not hide attention. */
      }
      const callback = env.OPENCODE_TERMINAL_HELPER
      if (!callback || !isAbsolute(callback) || !/^[a-zA-Z0-9_./-]+$/.test(callback))
        throw new Error("Absolute callback helper is required")
      const notifier = env.OPENCODE_TERMINAL_NOTIFIER || "terminal-notifier"
      run(notifier, [
        "-title",
        `OpenCode (${record.project || "terminal"}): ${record.title || "Attention"}`,
        "-message",
        `OpenCode: ${record.message || record.event}`,
        "-group",
        `opencode-${token}`,
        "-execute",
        `${callback} focus ${token}`,
      ])
    },
    plainNotification(title: unknown, message: unknown) {
      if (!env.TMUX) {
        try {
          const native = decodeGhostty(
            JSON.parse(run("/usr/bin/osascript", ["-l", "JavaScript", "-e", GHOSTTY_QUERY]))
          )
          if (native.frontmost) return
        } catch {
          /* Retain delivery when focus cannot be determined. */
        }
      }
      run(env.OPENCODE_TERMINAL_NOTIFIER || "terminal-notifier", [
        "-title",
        `OpenCode: ${cleanText(title) || "Attention"}`,
        "-message",
        `OpenCode: ${cleanText(message, 320) || "Attention"}`,
      ])
    },
    doctor() {
      let state = "absent"
      try {
        const info = lstatSync(stateDirectory)
        state =
          info.isDirectory() && !info.isSymbolicLink() && info.uid === uid && !(info.mode & 0o077)
            ? "private"
            : "unsafe"
      } catch (error) {
        if (errorCode(error) !== "ENOENT") throw error
      }
      let registration = "unavailable"
      if (state === "private" && socket && /^%\d+$/.test(pane ?? "")) {
        try {
          const token = tmuxAt(socket, "show-options", "-pqv", "-t", pane, OWNER_OPTION)
          registration = "none"
          if (UUID.test(token)) {
            const owner = read("owner", token)
            validate({ ...owner, owner: token, created: Date.now() }, false)
            registration = "live"
          }
        } catch {
          registration = "stale-or-unavailable"
        }
      }
      return {
        stateDirectory,
        state,
        tmuxPath,
        psPath,
        socket: socket || null,
        pane: pane || null,
        registration,
        nativeMapping: "not queried; doctor does not request OS consent",
      }
    },
  }
}

async function main(argv: string[]): Promise<void> {
  const context = createTerminalContext()
  if (argv[0] === "focus" && argv.length === 2) {
    const result = await context.focus(argv[1])
    console.log(JSON.stringify(result))
    return
  }
  if (argv[0] === "event") {
    const fields: Record<string, string> = {}
    for (let index = 1; index < argv.length; index += 2) {
      if (
        !["--event", "--session-id", "--title", "--message"].includes(argv[index]) ||
        argv[index + 1] === undefined
      )
        throw new Error("Invalid event arguments")
      fields[argv[index].slice(2)] = argv[index + 1]
    }
    if (!EVENTS.has(fields.event)) throw new Error("Unsupported attention event")
    const owner = process.env.OPENCODE_TERMINAL_OWNER
    if (!owner) {
      if (process.platform === "darwin") context.plainNotification(fields.title, fields.message)
      return
    }
    const token = await context.capture({
      owner,
      sessionID: fields["session-id"],
      event: fields.event as AttentionEvent,
      title: fields.title,
      message: fields.message,
    })
    if (process.platform === "darwin") await context.notify(token)
    return
  }
  if (argv[0] === "doctor" && argv.length === 1) {
    console.log(JSON.stringify(context.doctor(), null, 2))
    return
  }
  if (argv[0] === "refresh" && argv.length === 1) {
    context.refresh()
    return
  }
  if (argv[0] === "ack" && argv.length === 2) {
    context.ack(argv[1], true)
    return
  }
  if (
    ["inbox", "oldest"].includes(argv[0]) &&
    argv[1] === "--client" &&
    /^\/dev\/[a-zA-Z0-9/]+$/.test(argv[2] ?? "") &&
    argv.length === 3
  ) {
    context.refresh()
    const items = context.listAttention()
    if (!items.length) {
      if (argv[0] === "inbox") await inboxMessage("No OpenCode attention")
      else console.log("No OpenCode attention")
      return
    }
    let token = items[0].token
    if (argv[0] === "inbox") {
      const lines =
        items
          .map(
            (item) =>
              `${item.token}\t${item.project} | ${item.title} | ${item.event} | ${Math.floor((Date.now() - item.created) / 1000)}s`
          )
          .join("\n") + "\n"
      const choice = spawnSync(
        process.env.OPENCODE_TERMINAL_FZF || "fzf",
        [
          "--delimiter=\t",
          "--with-nth=2..",
          "--no-multi",
          "--preview=",
          "--preview-window=hidden",
          "--layout=reverse",
          "--expect=ctrl-d",
          "--header=Enter: visit, Ctrl+d: dismiss, Esc: cancel",
        ],
        { input: lines, encoding: "utf8", stdio: ["pipe", "pipe", "inherit"], timeout: 300000 }
      )
      if (choice.status === 1 || choice.status === 130) return
      if (choice.error || choice.status !== 0) throw new Error("Attention picker failed")
      const [key, row] = choice.stdout.split("\n")
      token = (row ?? "").split("\t")[0]
      if (!items.some((item) => item.token === token)) throw new Error("Invalid picker selection")
      if (key === "ctrl-d") {
        context.ack(token, true)
        return
      }
    }
    await context.focus(token, { client: argv[2] })
    return
  }
  throw new Error("Usage: opencode-terminal event|focus|inbox|oldest|ack|refresh|doctor")
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch(async (error) => {
    process.exitCode = 1
    const message = `opencode-terminal: ${error instanceof Error ? error.message : String(error)}`
    if (process.argv[2] === "inbox") await inboxMessage(message, process.stdin, process.stderr)
    else console.error(message)
  })
}
