import { spawn } from "node:child_process"
import { constants } from "node:fs"
import { chmod, lstat, mkdir, open, rename, rm, writeFile } from "node:fs/promises"
import { randomUUID } from "node:crypto"
import { homedir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { createInterface } from "node:readline/promises"
import { emitKeypressEvents, type Key } from "node:readline"
import { type Readable } from "node:stream"
import { fileURLToPath } from "node:url"
import { serveAffine } from "./opencode-affine.mts"
import { serveDocuments } from "./opencode-documents.mts"

type Service = "actualbudget" | "affine"
type Credentials = Record<string, string>

const services = {
  actualbudget: {
    required: ["ACTUAL_SERVER_URL", "ACTUAL_PASSWORD", "ACTUAL_BUDGET_SYNC_ID"],
    optional: ["ACTUAL_BUDGET_PASSWORD"],
    url: "ACTUAL_SERVER_URL",
    defaultUrl: "https://ab.shupi.ushira.com",
    entry: "actual-mcp-server/bin/actual-mcp-server.js",
  },
  affine: {
    required: ["AFFINE_BASE_URL", "AFFINE_EMAIL", "AFFINE_PASSWORD"],
    optional: ["AFFINE_WORKSPACE_ID"],
    url: "AFFINE_BASE_URL",
    defaultUrl: "https://ae.shupi.ushira.com",
    entry: "affine-mcp-server/bin/affine-mcp",
  },
} as const

export function credentialPath(service: Service, env = process.env) {
  return join(
    env.XDG_CONFIG_HOME || join(env.HOME || homedir(), ".config"),
    "opencode-assistant",
    `${service}.json`
  )
}

function validate(service: Service, value: unknown): Credentials {
  if (!value || typeof value !== "object" || Array.isArray(value))
    throw new Error("Expected a credential object")
  const spec = services[service]
  const allowed: readonly string[] = [...spec.required, ...spec.optional]
  const credentials = value as Credentials
  for (const [key, field] of Object.entries(credentials)) {
    if (!allowed.includes(key)) throw new Error(`Unsupported credential field: ${key}`)
    if (typeof field !== "string") throw new Error(`Credential field ${key} must be a string`)
  }
  for (const key of spec.required) {
    if (!credentials[key]?.trim()) throw new Error(`Missing credential field: ${key}`)
  }
  let url: URL
  try {
    url = new URL(credentials[spec.url]!)
  } catch {
    throw new Error(`Invalid URL in ${spec.url}`)
  }
  const loopback = ["localhost", "127.0.0.1", "[::1]"].includes(url.hostname)
  if (
    url.username ||
    url.password ||
    url.search ||
    url.hash ||
    (url.protocol !== "https:" && !(url.protocol === "http:" && loopback))
  ) {
    throw new Error(
      `${spec.url} requires HTTPS (or loopback HTTP), without URL credentials, query or fragment`
    )
  }
  return credentials
}

async function privateDirectory(path: string) {
  await mkdir(path, { recursive: true, mode: 0o700 })
  const info = await lstat(path)
  if (!info.isDirectory() || (process.getuid && info.uid !== process.getuid()))
    throw new Error(`Expected an owned directory: ${path}`)
  await chmod(path, 0o700)
}

export async function saveCredentials(
  service: Service,
  credentials: Credentials,
  env = process.env
) {
  validate(service, credentials)
  const path = credentialPath(service, env)
  await privateDirectory(dirname(path))
  try {
    if ((await lstat(path)).isSymbolicLink())
      throw new Error(`Refusing credential symbolic link: ${path}`)
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error
  }
  const temporary = `${path}.${randomUUID()}.tmp`
  try {
    await writeFile(temporary, JSON.stringify(credentials, null, 2) + "\n", {
      mode: 0o600,
      flag: "wx",
    })
    await rename(temporary, path)
  } finally {
    await rm(temporary, { force: true })
  }
}

export async function readCredentials(service: Service, env = process.env) {
  const path = credentialPath(service, env)
  let file
  try {
    file = await open(path, constants.O_RDONLY | constants.O_NOFOLLOW)
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT")
      throw new Error(`not configured. Run: opencode-assistant setup ${service}`)
    throw new Error(`Cannot open private credentials: ${path}`)
  }
  try {
    const info = await file.stat()
    if (
      !info.isFile() ||
      (info.mode & 0o077) !== 0 ||
      (process.getuid && info.uid !== process.getuid())
    ) {
      throw new Error(`Credentials must be an owned regular file with mode 0600: ${path}`)
    }
    let value: unknown
    try {
      value = JSON.parse(await file.readFile("utf8"))
    } catch {
      throw new Error(`Invalid credential JSON: ${path}; values omitted`)
    }
    return validate(service, value)
  } finally {
    await file.close()
  }
}

export async function launchPlan(service: Service, env = process.env) {
  const credentials = await readCredentials(service, env)
  const modules = env.OPENCODE_ASSISTANT_MODULES
  if (!modules)
    throw new Error(
      "Connector package path is missing; use the Nix-packaged opencode-assistant command"
    )
  const cwd = join(
    env.XDG_DATA_HOME || join(env.HOME || homedir(), ".local/share"),
    "opencode-assistant",
    service
  )
  await privateDirectory(dirname(cwd))
  await privateDirectory(cwd)
  try {
    await lstat(join(cwd, ".env"))
    throw new Error(`Unexpected .env in ${cwd}; move it aside before starting the connector`)
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error
  }
  const inherited = new Set([
    "PATH",
    "HOME",
    "TMPDIR",
    "TMP",
    "TEMP",
    "LANG",
    "LC_ALL",
    "LC_CTYPE",
    "TZ",
    "SSL_CERT_FILE",
    "NIX_SSL_CERT_FILE",
    "NODE_EXTRA_CA_CERTS",
    "NODE_USE_SYSTEM_CA",
    "HTTP_PROXY",
    "HTTPS_PROXY",
    "ALL_PROXY",
    "NO_PROXY",
    "http_proxy",
    "https_proxy",
    "all_proxy",
    "no_proxy",
  ])
  const childEnv: NodeJS.ProcessEnv = Object.fromEntries(
    Object.entries(env).filter(([key]) => inherited.has(key))
  )
  Object.assign(childEnv, credentials, { XDG_CONFIG_HOME: join(cwd, "config") })
  if (service === "actualbudget") {
    await privateDirectory(join(cwd, "cache"))
    Object.assign(childEnv, {
      MCP_READ_ONLY: "true",
      MCP_TOOLSETS: "chat,analysis",
      MCP_TOOLS: "actual_budgets_getMonths,actual_schedules_get",
      MCP_BRIDGE_DATA_DIR: join(cwd, "cache"),
      MCP_BRIDGE_STORE_LOGS: "false",
      MCP_BRIDGE_LOG_LEVEL: "warn",
      MCP_BRIDGE_DEBUG_TRANSPORT: "false",
      NODE_ENV: "production",
    })
  } else {
    Object.assign(childEnv, {
      MCP_TRANSPORT: "stdio",
      AFFINE_CLIENT_VERSION: "0.27.4",
      AFFINE_WS_CLIENT_VERSION: "0.27.4",
      AFFINE_TOOL_PROFILE: "core",
      AFFINE_DISABLED_GROUPS: "admin,destructive,docs.share,docs.database",
      AFFINE_DISABLED_TOOLS: "sign_in,trash_doc,restore_doc,move_block",
    })
  }
  return {
    cwd,
    env: childEnv,
    args: [
      join(modules, services[service].entry),
      ...(service === "actualbudget" ? ["--stdio"] : []),
    ],
  }
}

export async function readSecret(
  input: Readable & { isRaw?: boolean; setRawMode(raw: boolean): unknown }
) {
  const wasRaw = input.isRaw ?? false
  emitKeypressEvents(input)
  input.setRawMode(true)
  input.resume()
  try {
    return await new Promise<string>((accept, reject) => {
      let value = ""
      const finish = (error?: Error) => {
        input.off("keypress", receive)
        if (error) reject(error)
        else accept(value)
      }
      const receive = (text: string | undefined, key: Key) => {
        if (key.ctrl && (key.name === "c" || key.name === "d")) finish(new Error("Setup cancelled"))
        else if (key.name === "return" || key.name === "enter") finish()
        else if (key.name === "backspace") value = [...value].slice(0, -1).join("")
        else if (text && !key.ctrl && !key.meta && !text.includes("\u001b")) value += text
      }
      input.on("keypress", receive)
    })
  } finally {
    input.setRawMode(wasRaw)
    input.pause()
  }
}

async function prompt(label: string, secret = false, fallback = "") {
  const question = `${label}${fallback ? ` [${fallback}]` : ""}: `
  if (!secret) {
    const readline = createInterface({ input: process.stdin, output: process.stderr })
    try {
      return (await readline.question(question)).trim() || fallback
    } finally {
      readline.close()
    }
  }
  process.stderr.write(question)
  try {
    return await readSecret(process.stdin)
  } finally {
    process.stderr.write("\n")
  }
}

async function setup(service: Service) {
  if (!process.stdin.isTTY)
    throw new Error(
      "Run setup in your own terminal; credentials must not be sent through chat or command arguments"
    )
  const spec = services[service]
  const credentials: Credentials = {
    [spec.url]: await prompt("Server URL", false, spec.defaultUrl),
  }
  if (service === "actualbudget") {
    credentials.ACTUAL_BUDGET_SYNC_ID = await prompt(
      "Personal budget Sync ID (Actual Settings → Advanced)"
    )
    credentials.ACTUAL_PASSWORD = await prompt("Actual server password (hidden)", true)
    credentials.ACTUAL_BUDGET_PASSWORD = await prompt(
      "Budget encryption password (hidden; blank if unencrypted)",
      true
    )
  } else {
    credentials.AFFINE_EMAIL = await prompt("AFFiNE email")
    credentials.AFFINE_WORKSPACE_ID = await prompt(
      "Default workspace ID (optional; leave blank if unsure)"
    )
    credentials.AFFINE_PASSWORD = await prompt("AFFiNE password (hidden)", true)
  }
  await saveCredentials(service, credentials)
  process.stdout.write(
    `Saved private credentials to ${credentialPath(service)}. Restart OpenCode and check /assistant. Connection not checked.\n`
  )
}

async function main() {
  const [command, selected] = process.argv.slice(2)
  if (command === "status") {
    for (const service of ["actualbudget", "affine"] as const) {
      try {
        await readCredentials(service)
        process.stdout.write(`${service}: configured (connection not checked)\n`)
      } catch (error) {
        process.stdout.write(`${service}: ${(error as Error).message}\n`)
      }
    }
    return
  }
  if (command === "run" && selected === "documents") {
    const modules = process.env.OPENCODE_ASSISTANT_MODULES
    const reader = process.env.OPENCODE_DOCUMENT_READER
    if (!modules || !reader) throw new Error("Use the Nix-packaged opencode-assistant command")
    return serveDocuments(modules, reader)
  }
  if (
    (command !== "setup" && command !== "run") ||
    (selected !== "actualbudget" && selected !== "affine")
  ) {
    throw new Error(
      "Usage: opencode-assistant status | setup <actualbudget|affine> | run <actualbudget|affine|documents>"
    )
  }
  if (command === "setup") return setup(selected)
  const plan = await launchPlan(selected)
  if (selected === "affine") return serveAffine(plan, process.env.OPENCODE_ASSISTANT_MODULES!)
  const child = spawn(process.execPath, plan.args, {
    cwd: plan.cwd,
    env: plan.env,
    stdio: "inherit",
  })
  for (const signal of ["SIGINT", "SIGTERM"] as const) process.on(signal, () => child.kill(signal))
  child.on("error", () => {
    process.stderr.write(`Unable to start ${selected} connector\n`)
    process.exitCode = 1
  })
  child.on("exit", (code, signal) => {
    process.exitCode = code ?? (signal ? 1 : 0)
  })
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error: Error) => {
    process.stderr.write(`${error.message}\n`)
    process.exitCode = 1
  })
}
