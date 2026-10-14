import { spawn } from "node:child_process"
import { createHash, randomUUID } from "node:crypto"
import {
  chmodSync,
  closeSync,
  constants,
  fstatSync,
  lstatSync,
  mkdirSync,
  openSync,
  readFileSync,
  renameSync,
  rmdirSync,
  unlinkSync,
  writeFileSync,
} from "node:fs"
import { homedir } from "node:os"
import { join, resolve } from "node:path"
import { fileURLToPath, pathToFileURL } from "node:url"

export type QuotaWindow = { usedPercent: number; windowDurationMins: number; resetsAt: number }
type ReadResult =
  | { kind: "ok"; windows: QuotaWindow[]; resetCount?: number }
  | { kind: "auth" | "error" | "unavailable" }

function object(value: unknown): Record<string, unknown> | undefined {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined
}

function resetCount(value: unknown): number | undefined {
  return typeof value === "number" && Number.isSafeInteger(value) && value >= 0 ? value : undefined
}

export function decodeQuota(value: unknown): QuotaWindow[] {
  const result = object(value)
  if (!result) throw new Error("Invalid quota")
  const bucket = object(
    result.rateLimitsByLimitId === undefined || result.rateLimitsByLimitId === null
      ? result.rateLimits
      : object(result.rateLimitsByLimitId)?.codex
  )
  if (!bucket || (bucket.limitId != null && bucket.limitId !== "codex")) return []
  return [bucket.primary, bucket.secondary]
    .filter((value) => value != null)
    .map((value) => {
      const window = object(value)
      if (
        !window ||
        typeof window.usedPercent !== "number" ||
        !Number.isFinite(window.usedPercent) ||
        window.usedPercent < 0 ||
        window.usedPercent > 100 ||
        !Number.isSafeInteger(window.windowDurationMins) ||
        Number(window.windowDurationMins) <= 0 ||
        !Number.isSafeInteger(window.resetsAt) ||
        Number(window.resetsAt) <= 0
      ) {
        throw new Error("Invalid quota")
      }
      return {
        usedPercent: window.usedPercent,
        windowDurationMins: Number(window.windowDurationMins),
        resetsAt: Number(window.resetsAt),
      }
    })
    .sort((a, b) => a.windowDurationMins - b.windowDurationMins)
}

export function formatQuota(windows: QuotaWindow[]): string {
  if (!windows.length) return "CX:n/a"
  return windows
    .map((window) => {
      const duration = window.windowDurationMins
      const label =
        duration === 10080 ? "weekly" : duration % 60 === 0 ? `${duration / 60}h` : `${duration}m`
      return `${Math.round(100 - window.usedPercent)}% Codex Quota Remaining (${label})`
    })
    .join(" | ")
}

export function formatCompactQuota(windows: QuotaWindow[]): string {
  if (!windows.length) return "󰘥"
  const icons = ["󰫃", "󰫄", "󰫅", "󰫆", "󰫇", "󰫈"]
  return [...windows]
    .sort((a, b) => a.windowDurationMins - b.windowDurationMins)
    .map((window) => {
      const remaining = Math.round(100 - window.usedPercent)
      const level = Math.max(1, Math.min(6, Math.ceil((remaining * 6) / 100)))
      return `${icons[level - 1]} ${remaining}%`
    })
    .join(" | ")
}

function formatTimestamp(timestamp: number, timeZone: string): string {
  const formatted = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    weekday: "short",
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
    timeZoneName: "shortOffset",
  }).format(timestamp)
  return `${formatted} (${timeZone})`
}

export function formatFullQuota(
  windows: QuotaWindow[],
  now = Date.now(),
  timeZone = process.env.CODEX_QUOTA_TIMEZONE || "UTC",
  availableResets?: number
): string {
  const details = windows.map((window) => {
    const minutes = Math.max(0, Math.ceil((window.resetsAt * 1000 - now) / 60000))
    const days = Math.floor(minutes / 1440)
    const hours = Math.floor((minutes % 1440) / 60)
    const remainingMinutes = minutes % 60
    const countdown =
      window.resetsAt * 1000 <= now
        ? "due now; awaiting updated quota data"
        : `${days} ${days === 1 ? "day" : "days"}, ${hours} ${hours === 1 ? "hour" : "hours"}, ${remainingMinutes} ${remainingMinutes === 1 ? "minute" : "minutes"}`
    return `${formatQuota([window])}\n  Used: ${window.usedPercent}%\n  Next reset: ${formatTimestamp(window.resetsAt * 1000, timeZone)}\n  Reset in: ${countdown}`
  })
  const count = resetCount(availableResets)
  return `${details.join("\n\n")}\n\nManual resets remaining: ${count === undefined ? "unknown (not returned by Codex)" : count}`
}

export function readQuota(
  options: { command?: string; prefixArgs?: string[]; timeoutMs?: number } = {}
): Promise<ReadResult> {
  return new Promise((resolve) => {
    const child = spawn(
      options.command || "codex",
      [...(options.prefixArgs || []), "app-server", "--listen", "stdio://"],
      {
        stdio: ["pipe", "pipe", "ignore"],
      }
    )
    let closing: ReadResult | undefined
    let killTimer: ReturnType<typeof setTimeout> | undefined
    let buffer = "",
      total = 0,
      initialized = false
    const finish = (result: ReadResult) => {
      if (closing) return
      closing = result
      clearTimeout(timer)
      child.stdin.destroy()
      child.kill("SIGTERM")
      killTimer = setTimeout(() => child.kill("SIGKILL"), 500)
    }
    const timer = setTimeout(() => finish({ kind: "error" }), options.timeoutMs ?? 15000)
    const send = (message: unknown) => child.stdin.write(JSON.stringify(message) + "\n")
    child.on("error", () => finish({ kind: "unavailable" }))
    child.stdin.on("error", () => finish({ kind: "error" }))
    child.on("close", () => {
      clearTimeout(timer)
      clearTimeout(killTimer)
      resolve(closing || { kind: "error" })
    })
    child.stdout.setEncoding("utf8")
    child.stdout.on("data", (chunk: string) => {
      if (closing) return
      total += Buffer.byteLength(chunk)
      if (total > 262144) return finish({ kind: "error" })
      buffer += chunk
      while (buffer.includes("\n")) {
        const newline = buffer.indexOf("\n")
        const line = buffer.slice(0, newline)
        buffer = buffer.slice(newline + 1)
        if (Buffer.byteLength(line) > 65536) return finish({ kind: "error" })
        try {
          const message = object(JSON.parse(line))
          if (!message) throw new Error("Invalid message")
          if (message.id !== (initialized ? 2 : 1)) continue
          if (message.error) {
            const error = object(message.error)
            const auth =
              error?.code === 401 ||
              (typeof error?.message === "string" &&
                /not authenticated|not logged in|unauthorized|requires chatgpt authentication/i.test(
                  error.message
                ))
            return finish({ kind: auth ? "auth" : "error" })
          }
          if (!object(message.result)) throw new Error("Missing result")
          if (!initialized) {
            initialized = true
            send({ method: "initialized", params: {} })
            send({ id: 2, method: "account/rateLimits/read" })
          } else {
            const count = resetCount(
              object(object(message.result)?.rateLimitResetCredits)?.availableCount
            )
            return finish({
              kind: "ok",
              windows: decodeQuota(message.result),
              ...(count !== undefined ? { resetCount: count } : {}),
            })
          }
        } catch {
          return finish({ kind: "error" })
        }
      }
      if (Buffer.byteLength(buffer) > 65536) finish({ kind: "error" })
    })
    send({
      id: 1,
      method: "initialize",
      params: { clientInfo: { name: "tmux_quota", title: "Tmux quota", version: "0.1.0" } },
    })
  })
}

type State = {
  attemptedAt: number
  fetchedAt: number
  windows: QuotaWindow[]
  failure: string
  resetCount?: number
}
const refreshInterval = 300000,
  retryInterval = 60000,
  maxAge = 900000,
  lease = 30000

function readPrivate(path: string): unknown {
  const fd = openSync(path, constants.O_RDONLY | constants.O_NOFOLLOW)
  try {
    const stat = fstatSync(fd)
    if (
      !stat.isFile() ||
      stat.size > 16384 ||
      (stat.mode & 0o077) !== 0 ||
      stat.uid !== process.getuid?.()
    )
      throw new Error("Unsafe cache")
    return JSON.parse(readFileSync(fd, "utf8"))
  } finally {
    closeSync(fd)
  }
}

export function createQuotaCache(
  options: {
    directory?: string
    codexHome?: string
    now?: () => number
    launch?: (token: string) => void
    readOptions?: Parameters<typeof readQuota>[0]
  } = {}
) {
  const root =
    options.directory ||
    process.env.CODEX_QUOTA_CACHE_DIR ||
    join(process.env.XDG_CACHE_HOME || join(homedir(), ".cache"), "codex-quota")
  const home = resolve(options.codexHome || process.env.CODEX_HOME || join(homedir(), ".codex"))
  const directory = join(root, createHash("sha256").update(home).digest("hex").slice(0, 24))
  const statePath = join(directory, "state.json"),
    lockPath = join(directory, "lock.json"),
    recovery = join(directory, "recovery")
  const now = options.now || Date.now
  function prepare() {
    for (const path of [root, directory]) {
      mkdirSync(path, { recursive: true, mode: 0o700 })
      const stat = lstatSync(path)
      if (!stat.isDirectory() || stat.isSymbolicLink() || stat.uid !== process.getuid?.())
        throw new Error("Unsafe cache")
      chmodSync(path, 0o700)
    }
  }
  function state(): State | undefined {
    try {
      const data = object(readPrivate(statePath))
      if (
        !data ||
        !Number.isSafeInteger(data.attemptedAt) ||
        !Number.isSafeInteger(data.fetchedAt) ||
        Number(data.attemptedAt) > now() ||
        Number(data.fetchedAt) > now() ||
        !["none", "auth", "error", "unavailable"].includes(String(data.failure)) ||
        !Array.isArray(data.windows) ||
        data.windows.length > 2
      )
        return undefined
      const windows = decodeQuota({
        rateLimits: { primary: data.windows[0], secondary: data.windows[1] },
      })
      return {
        attemptedAt: Number(data.attemptedAt),
        fetchedAt: Number(data.fetchedAt),
        windows,
        failure: String(data.failure),
        resetCount: resetCount(data.resetCount),
      }
    } catch {
      return undefined
    }
  }
  function publish(value: State) {
    const temporary = join(directory, `${randomUUID()}.tmp`)
    try {
      writeFileSync(temporary, JSON.stringify(value), { flag: "wx", mode: 0o600 })
      renameSync(temporary, statePath)
    } finally {
      try {
        unlinkSync(temporary)
      } catch {}
    }
  }
  function lock(): { token: string; startedAt: number } | undefined {
    try {
      const value = object(readPrivate(lockPath))
      if (
        typeof value?.token !== "string" ||
        !/^[a-f0-9-]{36}$/.test(value.token) ||
        !Number.isSafeInteger(value.startedAt)
      )
        return undefined
      return { token: value.token, startedAt: Number(value.startedAt) }
    } catch {
      return undefined
    }
  }
  function release(token: string) {
    if (lock()?.token === token) unlinkSync(lockPath)
  }
  function acquire(): string | undefined {
    prepare()
    // Serialize expired-lease removal so simultaneous redraws cannot delete a new lease.
    try {
      const previous = lock()
      const stat = lstatSync(lockPath)
      if (now() - (previous?.startedAt ?? stat.mtimeMs) > lease) {
        mkdirSync(recovery, { mode: 0o700 })
        try {
          const current = lock()
          if (current?.token === previous?.token && now() - lstatSync(lockPath).mtimeMs > lease)
            unlinkSync(lockPath)
        } finally {
          rmdirSync(recovery)
        }
      }
    } catch {}
    try {
      if (lstatSync(recovery).isDirectory()) return undefined
    } catch {}
    const token = randomUUID()
    try {
      writeFileSync(lockPath, JSON.stringify({ token, startedAt: now() }), {
        flag: "wx",
        mode: 0o600,
      })
      try {
        lstatSync(recovery)
        release(token)
        return undefined
      } catch {}
      return token
    } catch {
      return undefined
    }
  }
  async function refresh(token?: string) {
    const owned = token || acquire()
    if (!owned || lock()?.token !== owned) return
    try {
      const previous = state()
      const result = await readQuota(
        options.readOptions || { command: process.env.CODEX_QUOTA_CODEX || "codex" }
      )
      if (lock()?.token !== owned) return
      const success = result.kind === "ok" && result.windows.length > 0
      publish({
        attemptedAt: now(),
        fetchedAt: success ? now() : previous?.fetchedAt || 0,
        windows: success ? result.windows : result.kind === "error" ? previous?.windows || [] : [],
        failure: success ? "none" : result.kind === "ok" ? "unavailable" : result.kind,
        resetCount: success
          ? result.resetCount
          : result.kind === "error"
            ? previous?.resetCount
            : undefined,
      })
    } finally {
      release(owned)
    }
  }
  function launch(token: string) {
    if (options.launch) return options.launch(token)
    const child = spawn(process.execPath, [fileURLToPath(import.meta.url), "refresh", token], {
      detached: true,
      stdio: "ignore",
      env: { ...process.env, CODEX_QUOTA_CACHE_DIR: root, CODEX_HOME: home },
    })
    child.on("error", () => {
      try {
        publish({ attemptedAt: now(), fetchedAt: 0, windows: [], failure: "error" })
        release(token)
      } catch {}
    })
    child.unref()
  }
  function status(detailed = false): string {
    const unavailable = detailed ? "Codex quota unavailable." : "󰘥"
    try {
      prepare()
      const current = state(),
        age = current ? now() - current.fetchedAt : Infinity
      const reset = current?.windows.some((window) => window.resetsAt * 1000 <= now()) ?? false
      const crossedReset =
        current?.windows.some(
          (window) => window.resetsAt * 1000 <= now() && current.fetchedAt < window.resetsAt * 1000
        ) ?? false
      const due =
        !current ||
        (current.failure !== "none"
          ? now() - current.attemptedAt >= retryInterval
          : age >= refreshInterval || crossedReset)
      if (due) {
        const token = acquire()
        if (token) {
          try {
            launch(token)
          } catch {
            publish({ attemptedAt: now(), fetchedAt: 0, windows: [], failure: "error" })
            release(token)
            return unavailable
          }
        }
      }
      if (!current)
        return detailed ? "Codex quota loading; run codex-quota full again shortly." : "󰝲"
      if (!current.windows.length || age > maxAge) return unavailable
      if (detailed) {
        return (
          formatFullQuota(
            current.windows,
            now(),
            process.env.CODEX_QUOTA_TIMEZONE || "UTC",
            current.resetCount
          ) +
          `\nCached snapshot: ${formatTimestamp(current.fetchedAt, process.env.CODEX_QUOTA_TIMEZONE || "UTC")}` +
          (age >= refreshInterval || reset || current.failure !== "none" ? "\nSnapshot: stale" : "")
        )
      }
      return (
        formatCompactQuota(current.windows) +
        (age >= refreshInterval || reset || current.failure !== "none" ? " 󰅐" : "")
      )
    } catch {
      return unavailable
    }
  }
  return { directory, status: () => status(), full: () => status(true), refresh }
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  const args = process.argv.slice(2)
  const usage =
    "Usage:\n  codex-quota status  Show the compact tmux quota status\n  codex-quota full    Show quota windows and time until reset\n  codex-quota help    Show available commands"
  if (!args.length || (args.length === 1 && ["help", "--help", "-h"].includes(args[0]))) {
    console.log(usage)
  } else {
    const cache = createQuotaCache()
    if (args[0] === "status" && args.length === 1) console.log(cache.status())
    else if (args[0] === "full" && args.length === 1) console.log(cache.full())
    else if (args[0] === "refresh" && args.length <= 2) {
      try {
        await cache.refresh(args[1])
      } catch {
        process.exitCode = 1
      }
    } else {
      console.error(usage)
      process.exitCode = 1
    }
  }
}
