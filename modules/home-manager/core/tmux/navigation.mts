import { createHash } from "node:crypto"
import { execFileSync, spawnSync } from "node:child_process"
import { readFileSync, readdirSync, realpathSync, statSync } from "node:fs"
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path"
import { fileURLToPath } from "node:url"

export interface NavigationSettings {
  home: string
  manualPaths: string[]
  roots: { path: string; minDepth: number; maxDepth: number }[]
}

export interface NavigationProject {
  path: string
  label: string
  group: string
}

function hasControls(value: string): boolean {
  return /\p{Cc}/u.test(value)
}

function display(value: string): string {
  return value.replace(/[\p{Cc}#]/gu, "_")
}

export function groupLabel(path: string, home: string): string {
  if (!isAbsolute(path) || !isAbsolute(home) || hasControls(path) || hasControls(home)) {
    return "Other"
  }
  const code = join(resolve(home), "Code")
  const location = relative(code, resolve(path))
  if (location === ".." || location.startsWith(`..${sep}`) || isAbsolute(location)) {
    return "Local"
  }
  const parent = dirname(location)
  return parent === "." ? "Code" : display(parent.split(sep).join(" / "))
}

export function canonicalDirectory(path: string): string {
  if (!isAbsolute(path) || hasControls(path)) throw new Error("Invalid directory path")
  try {
    const canonical = realpathSync(path)
    if (hasControls(canonical) || !statSync(canonical).isDirectory()) {
      throw new Error("Invalid directory")
    }
    return canonical
  } catch {
    // Filesystem errors can contain untrusted path text; expose a fixed diagnostic instead.
    throw new Error("Directory is unavailable or invalid")
  }
}

export function discoverProjects(settings: NavigationSettings): NavigationProject[] {
  const projects = new Map<string, NavigationProject>()
  function add(path: string): void {
    try {
      const canonical = canonicalDirectory(path)
      projects.set(canonical, {
        path: canonical,
        label: display(basename(canonical)) || "project",
        group: groupLabel(canonical, settings.home),
      })
    } catch {
      // Missing manual paths and directories removed during discovery are ineligible.
    }
  }
  for (const path of settings.manualPaths) add(path)
  for (const root of settings.roots) {
    if (
      !Number.isSafeInteger(root.minDepth) ||
      !Number.isSafeInteger(root.maxDepth) ||
      root.minDepth < 0 ||
      root.maxDepth < root.minDepth
    )
      continue
    let start: string
    try {
      start = canonicalDirectory(root.path)
    } catch {
      continue
    }
    // Resolve a configured root once; child symlinks are never traversal candidates.
    const pending = [{ path: start, depth: 0 }]
    while (pending.length > 0) {
      const current = pending.pop()!
      if (current.depth >= root.minDepth) add(current.path)
      if (current.depth >= root.maxDepth) continue
      try {
        for (const entry of readdirSync(current.path, { withFileTypes: true })) {
          if (!entry.isDirectory() || entry.name.startsWith(".") || hasControls(entry.name))
            continue
          pending.push({ path: join(current.path, entry.name), depth: current.depth + 1 })
        }
      } catch {
        // An unreadable or vanished subtree does not hide the other candidates.
      }
    }
  }
  const compare = (left: string, right: string): number =>
    left < right ? -1 : left > right ? 1 : 0
  return [...projects.values()].sort(
    (left, right) =>
      compare(left.group, right.group) ||
      compare(left.label, right.label) ||
      compare(left.path, right.path)
  )
}

export function preferredSessionName(path: string): string {
  return display(basename(path)).replace(/[.:]/gu, "_") || "project"
}

export function collisionSessionName(path: string): string {
  const canonical = canonicalDirectory(path)
  const suffix = createHash("sha256").update(canonical).digest("hex").slice(0, 8)
  return `${preferredSessionName(canonical)}-${suffix}`
}

export interface NavigationSession {
  id: string
  name: string
  path: string
  group: string
}

type Runner = (args: string[]) => string
const SESSION_ID = /^\$\d+$/
const CLIENT_NAME = /^\/dev\/[a-zA-Z0-9/]+$/

function settingsFromFile(): NavigationSettings {
  const file = process.env.TMUX_NAVIGATION_SETTINGS
  if (!file) throw new Error("Navigation settings are unavailable")
  const value: unknown = JSON.parse(readFileSync(file, "utf8"))
  if (!value || typeof value !== "object") throw new Error("Invalid navigation settings")
  const data = value as Partial<NavigationSettings>
  if (
    typeof data.home !== "string" ||
    !isAbsolute(data.home) ||
    !Array.isArray(data.manualPaths) ||
    !data.manualPaths.every((path) => typeof path === "string" && isAbsolute(path)) ||
    !Array.isArray(data.roots) ||
    !data.roots.every(
      (root) =>
        root &&
        typeof root.path === "string" &&
        isAbsolute(root.path) &&
        Number.isSafeInteger(root.minDepth) &&
        Number.isSafeInteger(root.maxDepth) &&
        root.minDepth >= 0 &&
        root.maxDepth <= 3 &&
        root.maxDepth >= root.minDepth
    )
  ) {
    throw new Error("Invalid navigation settings")
  }
  return data as NavigationSettings
}

function socketFromEnvironment(): string | undefined {
  const value = process.env.TMUX
  if (!value) return
  const last = value.lastIndexOf(",")
  const previous = value.lastIndexOf(",", last - 1)
  return previous > 0 ? value.slice(0, previous) : undefined
}

function runner(socket?: string): Runner {
  if (socket && (!isAbsolute(socket) || hasControls(socket))) throw new Error("Invalid tmux socket")
  return (args) => {
    try {
      return execFileSync(
        process.env.TMUX_NAVIGATION_TMUX || "tmux",
        [...(socket ? ["-S", socket] : []), ...args],
        {
          encoding: "utf8",
          timeout: 2500,
          maxBuffer: 256 * 1024,
          stdio: ["ignore", "pipe", "pipe"],
          env: { ...process.env, LC_ALL: "C" },
        }
      ).trimEnd()
    } catch {
      throw new Error("tmux operation failed or target became unavailable")
    }
  }
}

export function activeSessions(run: Runner, home: string): NavigationSession[] {
  const ids = run(["list-sessions", "-F", "#{session_id}"]).split("\n").filter(Boolean)
  if (ids.some((id) => !SESSION_ID.test(id))) throw new Error("Invalid session identity")
  return ids
    .map((id) => {
      const name = run(["display-message", "-p", "-t", `${id}:`, "#{session_name}"])
      const path = run(["display-message", "-p", "-t", `${id}:`, "#{session_path}"])
      return { id, name, path, group: groupLabel(path, home) }
    })
    .sort(
      (a, b) =>
        a.group.localeCompare(b.group) || a.name.localeCompare(b.name) || a.id.localeCompare(b.id)
    )
}

function clientSnapshot(run: Runner, requested?: string): { name: string; pid: string } {
  const rows = run(["list-clients", "-F", "#{client_name}|#{client_pid}|#{pane_id}"])
    .split("\n")
    .map((line) => line.split("|"))
    .filter(([name, pid]) => CLIENT_NAME.test(name) && /^\d+$/.test(pid))
  const candidates = requested
    ? rows.filter((row) => row[0] === requested)
    : rows.filter((row) => row[2] === process.env.TMUX_PANE)
  const selected =
    candidates.length === 1 ? candidates[0] : !requested && rows.length === 1 ? rows[0] : undefined
  if (!selected) throw new Error("Calling tmux client is unavailable or ambiguous")
  return { name: selected[0], pid: selected[1] }
}

function selectSession(run: Runner, id: string, client: { name: string; pid: string }): void {
  if (!SESSION_ID.test(id)) throw new Error("Invalid selected session")
  const current = clientSnapshot(run, client.name)
  if (current.pid !== client.pid) throw new Error("Calling client has changed")
  run(["display-message", "-p", "-t", `${id}:`, "#{session_id}"])
  run(["switch-client", "-c", client.name, "-t", id])
}

export function numberBindings(): string[] {
  return Array.from({ length: 10 }, (_, index) => {
    const key = index === 9 ? "0" : String(index + 1)
    // FZF_QUERY is environment data, never inserted into shell source.
    return `${key}:transform:if [ -z "$FZF_QUERY" ]; then if [ "\${FZF_MATCH_COUNT:-0}" -ge ${index + 1} ]; then printf 'pos(${index + 1})+accept'; else printf 'ignore'; fi; else printf 'put(${key})'; fi`
  })
}

function pick(
  rows: { key: string; label: string }[],
  sessions = false,
  preview = false
): string | undefined {
  if (!rows.length) throw new Error(sessions ? "No active tmux sessions" : "No eligible projects")
  const args = [
    "--delimiter=\t",
    "--with-nth=2..",
    "--no-multi",
    "--layout=reverse",
    "--no-sort",
    "--preview=",
    "--preview-window=hidden",
    sessions
      ? "--header=1–9/0: visit before search | Type to search | Enter: visit | Esc: cancel"
      : "--header=Type to search | Enter: open project | Esc: cancel",
  ]
  if (sessions) args.push("--bind", numberBindings().join(","))
  if (preview) {
    const helper = process.env.TMUX_NAVIGATION_HELPER
    if (!helper || !isAbsolute(helper) || !/^[a-zA-Z0-9_./-]+$/.test(helper))
      throw new Error("Absolute preview helper is unavailable")
    args.push(`--preview=${helper} preview {1}`, "--preview-window=right:40%")
  }
  const result = spawnSync(process.env.TMUX_NAVIGATION_FZF || "fzf", args, {
    input: rows.map((row) => `${row.key}\t${display(row.label)}`).join("\n") + "\n",
    encoding: "utf8",
    stdio: ["pipe", "pipe", "inherit"],
    timeout: 300000,
    env: { ...process.env, FZF_DEFAULT_OPTS: "", FZF_DEFAULT_OPTS_FILE: "" },
  })
  if (result.status === 1 || result.status === 130) return
  if (result.error || result.status !== 0) throw new Error("Navigation picker failed")
  const key = result.stdout.split("\t")[0]
  if (!rows.some((row) => row.key === key)) throw new Error("Invalid picker selection")
  return key
}

export function sessionsForProject(items: NavigationSession[], path: string): NavigationSession[] {
  const canonical = canonicalDirectory(path)
  return items.filter((item) => {
    try {
      return canonicalDirectory(item.path) === canonical
    } catch {
      return false
    }
  })
}

function previewDirectory(key: string): void {
  if (!/^[a-zA-Z0-9_-]+$/.test(key)) throw new Error("Invalid preview identity")
  const path = canonicalDirectory(Buffer.from(key, "base64url").toString("utf8"))
  console.log(display(path))
  const entries = readdirSync(path, { withFileTypes: true })
    .filter((entry) => !entry.name.startsWith("."))
    .sort(
      (a, b) => Number(b.isDirectory()) - Number(a.isDirectory()) || a.name.localeCompare(b.name)
    )
    .slice(0, 40)
  for (const entry of entries)
    console.log(`${entry.isDirectory() ? "d " : "  "}${display(entry.name)}`)
}

function openProject(
  run: Runner,
  path: string,
  settings: NavigationSettings,
  items: NavigationSession[]
): string | undefined {
  const canonical = canonicalDirectory(path)
  const existing = sessionsForProject(items, canonical)
  if (existing.length === 1) return existing[0].id
  if (existing.length > 1)
    return pick(existing.map((item) => ({ key: item.id, label: `${item.group} › ${item.name}` })))
  let name = preferredSessionName(canonical)
  if (items.some((item) => item.name === name)) name = collisionSessionName(canonical)
  if (items.some((item) => item.name === name))
    throw new Error("Project session name is already occupied")
  canonicalDirectory(canonical)
  try {
    const id = run(["new-session", "-d", "-P", "-F", "#{session_id}", "-s", name, "-c", canonical])
    if (!SESSION_ID.test(id)) throw new Error("Invalid created session identity")
    return id
  } catch {
    // A simultaneous opener may have created exactly this project; never reuse a name alone.
    const raced = sessionsForProject(activeSessions(run, settings.home), canonical).filter(
      (item) => item.name === name
    )
    if (raced.length === 1) return raced[0].id
    throw new Error("Project session creation failed or became ambiguous")
  }
}

async function main(argv: string[]): Promise<void> {
  const settings = settingsFromFile()
  const mode = argv.shift()
  if (mode === "preview" && argv.length === 1) {
    previewDirectory(argv[0])
    return
  }
  let socket = socketFromEnvironment(),
    requestedClient: string | undefined
  let projectPath: string | undefined
  while (argv.length) {
    const option = argv.shift()
    if (mode === "projects" && option && !option.startsWith("--") && !projectPath) {
      projectPath = resolve(option)
      continue
    }
    const value = argv.shift()
    if (!value || (option !== "--client" && option !== "--socket"))
      throw new Error("Invalid navigation arguments")
    if (option === "--socket") socket = value
    else requestedClient = value
  }
  const run = runner(socket)
  if (mode === "sessions") {
    const client = socket ? clientSnapshot(run, requestedClient) : undefined
    const items = activeSessions(run, settings.home)
    const key = pick(
      items.map((item, index) => ({
        key: item.id,
        label: `${index + 1}  ${item.group} › ${item.name}`,
      })),
      true
    )
    if (key && client) selectSession(run, key, client)
    else if (key) {
      const result = spawnSync(
        process.env.TMUX_NAVIGATION_TMUX || "tmux",
        ["attach-session", "-t", key],
        { stdio: "inherit" }
      )
      if (result.error || result.status !== 0) throw new Error("Session attach failed")
    }
    return
  }
  if (mode === "projects") {
    const client = socket ? clientSnapshot(run, requestedClient) : undefined
    if (!projectPath) {
      const projects = discoverProjects(settings)
      const key = pick(
        projects.map((item) => ({
          key: Buffer.from(item.path).toString("base64url"),
          label: `${item.group} › ${item.label}  (${item.path})`,
        })),
        false,
        true
      )
      if (!key) return
      projectPath = projects.find(
        (item) => Buffer.from(item.path).toString("base64url") === key
      )?.path
      if (!projectPath) throw new Error("Selected project is unavailable")
    }
    let items: NavigationSession[] = []
    try {
      items = activeSessions(run, settings.home)
    } catch {
      if (socket) throw new Error("Project server became unavailable")
    }
    if (client) {
      const current = clientSnapshot(run, client.name)
      if (current.pid !== client.pid)
        throw new Error("Calling client changed before project creation")
    }
    const id = openProject(run, projectPath, settings, items)
    if (!id) return
    if (client) selectSession(run, id, client)
    else {
      const result = spawnSync(
        process.env.TMUX_NAVIGATION_TMUX || "tmux",
        ["attach-session", "-t", id],
        { stdio: "inherit" }
      )
      if (result.error || result.status !== 0) throw new Error("Project attach failed")
    }
    return
  }
  throw new Error("Usage: tmux-navigation sessions|projects [path] [--client name] [--socket path]")
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch((error: unknown) => {
    console.error(`tmux-navigation: ${error instanceof Error ? error.message : "operation failed"}`)
    process.exitCode = 1
  })
}
