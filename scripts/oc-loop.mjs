import { spawn } from "node:child_process"
import { randomUUID } from "node:crypto"
import {
  chmodSync,
  closeSync,
  lstatSync,
  mkdirSync,
  openSync,
  realpathSync,
  renameSync,
  statSync,
  unlinkSync,
  writeFileSync,
} from "node:fs"
import { homedir } from "node:os"
import { isAbsolute, join } from "node:path"
import { createInterface } from "node:readline"
import { setTimeout as sleep } from "node:timers/promises"
import { parseArgs } from "node:util"

const help = `Usage: oc-loop --session ses_ID --prompt "Continue ..." [options]

  --dir PATH          Project directory (default: current directory)
  --done-token TEXT   Exact final assistant response that means done
                      (default: PROJECT_ENTIRELY_COMPLETE)
  --max-retries N     Failed-turn retries (default: unlimited; optional limit 0–10)
  --retry-delay N     Initial retry delay in seconds (default: 5)
  --turn-timeout N    Seconds before a hung turn is restarted (default: 7200)
  --help              Show this help

No overall turn limit. Permissions auto-approve; questions select their first option.
Explicit denies remain denied. Ctrl-C cancels; only the exact final token completes.
Exit codes: 0 DONE, 2 BLOCKED/invalid arguments, 130/143 CANCELLED.
State/logs: $XDG_STATE_HOME/oc-loop/ses_ID (default: ~/.local/state).
OC_LOOP_OPENCODE overrides the opencode executable. Global configuration is unchanged.
Use an idle local session; do not send prompts from another client while looping.
`

function options() {
  const { values } = parseArgs({
    options: {
      session: { type: "string" },
      prompt: { type: "string" },
      dir: { type: "string", default: process.cwd() },
      "done-token": { type: "string", default: "PROJECT_ENTIRELY_COMPLETE" },
      "max-retries": { type: "string", default: "unlimited" },
      "retry-delay": { type: "string", default: "5" },
      "turn-timeout": { type: "string", default: "7200" },
      help: { type: "boolean" },
    },
  })
  if (values.help) return
  if (!/^ses_[a-zA-Z0-9]+$/.test(values.session ?? ""))
    throw new Error("--session must be an exact ses_ session ID")
  if (!values.prompt?.trim()) throw new Error("--prompt is required")
  if (!/^[A-Za-z][A-Za-z0-9_:-]{0,127}$/.test(values["done-token"])) {
    throw new Error("--done-token must be a single identifier of 1–128 characters")
  }
  for (const [key, min, max] of [
    ["max-retries", 0, 10],
    ["retry-delay", 0, 60],
    ["turn-timeout", 1, 604800],
  ]) {
    if (key === "max-retries" && values[key] === "unlimited") continue
    if (!/^\d+$/.test(values[key]) || Number(values[key]) < min || Number(values[key]) > max) {
      throw new Error(`--${key} must be an integer from ${min} to ${max}`)
    }
    values[key] = Number(values[key])
  }
  const directory = realpathSync(values.dir)
  if (!statSync(directory).isDirectory()) throw new Error("--dir must be a directory")
  if (["1", "true"].includes(process.env.OPENCODE_PURE)) {
    throw new Error("Automatic question replies require plugins; OPENCODE_PURE is enabled")
  }
  const injected = JSON.parse(process.env.OPENCODE_CONFIG_CONTENT || "{}")
  if (
    !injected ||
    typeof injected !== "object" ||
    Array.isArray(injected) ||
    (injected.plugin !== undefined && !Array.isArray(injected.plugin))
  ) {
    throw new Error("OPENCODE_CONFIG_CONTENT must be a config object with an optional plugin array")
  }
  const configContent = JSON.stringify({
    ...injected,
    plugin: [
      ...(injected.plugin || []),
      [new URL("./oc-loop-autonomy.mjs", import.meta.url).href, { sessionID: values.session }],
    ],
  })
  return { ...values, dir: directory, configContent }
}

function storage(config) {
  const stateHome = process.env.XDG_STATE_HOME || join(homedir(), ".local", "state")
  if (!isAbsolute(stateHome)) throw new Error("XDG_STATE_HOME must be absolute")
  const base = join(stateHome, "oc-loop")
  const directory = join(base, config.session)
  for (const path of [base, directory]) {
    mkdirSync(path, { recursive: true, mode: 0o700 })
    const stat = lstatSync(path)
    if (!stat.isDirectory() || stat.uid !== process.getuid())
      throw new Error(`Not an owned state directory: ${path}`)
    chmodSync(path, 0o700)
  }
  const lock = join(directory, "lock")
  let lockFD
  try {
    lockFD = openSync(lock, "wx", 0o600)
  } catch (error) {
    if (error.code === "EEXIST")
      throw new Error(
        `Session locked: ${lock}. Check its owner; stale locks are not automatically removed.`
      )
    throw error
  }
  let logFD
  const id = randomUUID()
  const log = join(directory, `run-${id}.jsonl`)
  const temporary = join(directory, `status-${id}.tmp`)
  const cleanup = () => {
    if (logFD !== undefined) closeSync(logFD)
    closeSync(lockFD)
    unlinkSync(lock)
  }
  try {
    writeFileSync(
      lockFD,
      JSON.stringify({ pid: process.pid, session: config.session, directory: config.dir }) + "\n"
    )
    logFD = openSync(log, "wx", 0o600)
    return {
      log,
      record(data) {
        writeFileSync(logFD, JSON.stringify({ time: new Date().toISOString(), ...data }) + "\n")
      },
      status(status, turn, message) {
        writeFileSync(
          temporary,
          JSON.stringify({
            status,
            session: config.session,
            directory: config.dir,
            pid: process.pid,
            turn,
            message,
            log,
            updatedAt: new Date().toISOString(),
          }) + "\n",
          { flag: "wx", mode: 0o600 }
        )
        renameSync(temporary, join(directory, "status.json"))
      },
      close: cleanup,
    }
  } catch (error) {
    cleanup()
    throw error
  }
}

function failure(message, retryable = true) {
  return Object.assign(new Error(message), { retryable })
}

function prompt(config) {
  return `${config.prompt}

Autonomous operation:
Pending tool permissions are auto-approved within existing deny rules. Do not
pause for confirmation or ask the user to validate intermediate milestones.
Choose the FIRST listed option when a decision is needed. If you use the question
tool, the runner answers the first option of each question automatically.
Keep working within the agreed scope; this does not authorize unrelated work.

Completion contract:
Continue the agreed project scope, not just the current milestone. A step limit,
progress summary or successful intermediate check is not project completion.
Run the required validation; fix failures and continue with unfinished work.
Do not invent new scope. Do not bypass permissions, weaken checks, or treat a
missing prerequisite, unavailable required check, or approval request as success.
Only when every agreed requirement is implemented, all required checks freshly
pass, and no known in-scope bugs, review findings, tasks, blockers, skipped checks
or deferred work remain, make your FINAL assistant response exactly this token:
${config["done-token"]}
Do not quote, explain or emit that token unless those conditions are satisfied.
`
}

async function runTurn(config, state, turn, cancellation) {
  const args = [
    "run",
    "--dir",
    config.dir,
    "--session",
    config.session,
    "--format",
    "json",
    "--auto",
  ]
  const child = spawn(process.env.OC_LOOP_OPENCODE || "opencode", args, {
    cwd: config.dir,
    env: {
      ...process.env,
      CI: "true",
      GIT_TERMINAL_PROMPT: "0",
      GIT_EDITOR: "true",
      GIT_PAGER: "cat",
      PAGER: "cat",
      GCM_INTERACTIVE: "never",
      npm_config_yes: "true",
      PIP_NO_INPUT: "1",
      OPENCODE_CONFIG_CONTENT: config.configContent,
    },
    stdio: ["pipe", "pipe", "pipe"],
    detached: true,
  })
  const exited = new Promise((resolve) => {
    child.once("error", (error) => resolve({ code: 1, error }))
    child.once("close", (code, signal) => resolve({ code, signal }))
  })
  let terminating = false
  let killTimer
  const kill = (signal) => {
    if (!child.pid) return
    try {
      process.kill(-child.pid, signal)
    } catch (error) {
      if (error.code !== "ESRCH") throw error
    }
  }
  const terminate = () => {
    if (terminating) return
    terminating = true
    kill("SIGTERM")
    killTimer = setTimeout(() => kill("SIGKILL"), 5000)
  }
  let timedOut = false
  const timeout = setTimeout(() => {
    timedOut = true
    terminate()
  }, config["turn-timeout"] * 1000)
  cancellation.signal.addEventListener("abort", terminate, { once: true })
  child.stdin.on("error", () => {})
  child.stdin.end(prompt(config))
  let latest
  let finish
  let sessionError
  let blocked
  let autonomyReady = false
  let stderr = ""
  const texts = new Map()
  const record = (stream, data) => {
    try {
      state.record({ turn, stream, data })
    } catch {
      blocked = "Cannot write the run log"
      terminate()
    }
  }
  child.stderr.on("data", (data) => {
    record("stderr", data.toString())
    stderr = (stderr + data.toString()).slice(-8192)
    // OpenCode 1.18.35 prints permission auto-rejections to stderr, not JSON.
    if (/permission requested:.*auto-rejecting/.test(stderr))
      blocked = "A permission request needs human approval"
  })
  try {
    for await (const line of createInterface({ input: child.stdout, crlfDelay: Infinity })) {
      record("stdout", line)
      let event
      try {
        event = JSON.parse(line)
      } catch {
        if (/permission requested:.*auto-rejecting/.test(line))
          blocked = "A permission request needs human approval"
        if (line.trim().startsWith("{")) blocked = "Malformed OpenCode JSON event"
        continue
      }
      if (event?.sessionID !== config.session) continue
      if (event.type === "oc_loop_autonomy") {
        if (event.status === "ready") autonomyReady = true
        if (event.status === "error") blocked = event.message || "Automatic question reply failed"
        continue
      }
      if (event.type === "error") {
        sessionError = JSON.stringify(event.error ?? { name: "UnknownError" })
        continue
      }
      const part = event.part
      if (!part?.messageID) continue
      if (part.sessionID && part.sessionID !== config.session) {
        blocked = "Inconsistent event session"
        continue
      }
      if (event.type === "tool_use" && part.tool === "question" && part.state?.status === "error") {
        blocked = "Automatic question reply failed"
      }
      if (latest !== part.messageID) {
        latest = part.messageID
        finish = undefined
        texts.clear()
      }
      if (event.type === "text") {
        if (typeof part.text !== "string") blocked = "Invalid assistant text event"
        else texts.set(part.id ?? "text", part.text)
      }
      if (event.type === "step_finish") finish = part.reason
    }
    const result = await exited
    if (cancellation.signal.aborted) throw failure("Cancelled by operator")
    if (timedOut) throw failure(`Turn timed out after ${config["turn-timeout"]} seconds`)
    if (blocked) throw failure(blocked, blocked !== "Cannot write the run log")
    if (result.code !== 0 || sessionError) {
      const detail = sessionError || stderr || result.error?.message || `signal ${result.signal}`
      throw failure(`OpenCode failed (exit ${result.code}): ${detail.slice(-2048)}`)
    }
    if (!autonomyReady) throw failure("The automatic question helper did not load")
    if (!["stop", "length", "tool-calls"].includes(finish))
      throw failure("OpenCode returned without a completed assistant step")
    return finish === "stop" && [...texts.values()].join("\n").trim() === config["done-token"]
  } finally {
    clearTimeout(timeout)
    cancellation.signal.removeEventListener("abort", terminate)
    if (child.exitCode === null && child.signalCode === null) terminate()
    if (terminating) {
      kill("SIGKILL")
      await exited
    }
    clearTimeout(killTimer)
  }
}

async function main() {
  const config = options()
  if (!config) {
    process.stdout.write(help)
    return
  }
  const state = storage(config)
  const cancellation = new AbortController()
  let exitCode
  const onInterrupt = () => {
    exitCode = 130
    cancellation.abort()
  }
  const onTerminate = () => {
    exitCode = 143
    cancellation.abort()
  }
  process.on("SIGINT", onInterrupt)
  process.on("SIGTERM", onTerminate)
  let turn = 1
  let retries = 0
  process.stderr.write(
    "oc-loop: autonomous mode: approve pending permissions; answer questions with option one\n"
  )
  process.stderr.write(`oc-loop: logs ${state.log}\n`)
  try {
    for (; ; turn++) {
      if (cancellation.signal.aborted) throw failure("Cancelled by operator")
      state.status("RUNNING", turn)
      process.stderr.write(`oc-loop: turn ${turn} (${config.session})\n`)
      let done
      try {
        done = await runTurn(config, state, turn, cancellation)
      } catch (error) {
        if (cancellation.signal.aborted || !error.retryable) throw error
        if (config["max-retries"] !== "unlimited" && retries >= config["max-retries"])
          throw failure(`Failed-turn retries exhausted: ${error.message}`)
        const delay = Math.min(60, config["retry-delay"] * 2 ** Math.min(retries++, 6))
        state.status("RETRYING", turn, error.message)
        process.stderr.write(
          `oc-loop: failed turn; retry ${retries}/${config["max-retries"]} in ${delay}s\n`
        )
        await sleep(delay * 1000, undefined, { signal: cancellation.signal })
        turn--
        continue
      }
      retries = 0
      if (done) {
        state.status("DONE", turn)
        process.stdout.write(`DONE ${config.session}\n`)
        return
      }
    }
  } catch (error) {
    const status = cancellation.signal.aborted ? "CANCELLED" : "BLOCKED"
    state.status(status, turn, error.message)
    process.stderr.write(`${status}: ${error.message}\n`)
    process.exitCode = exitCode || 2
  } finally {
    process.off("SIGINT", onInterrupt)
    process.off("SIGTERM", onTerminate)
    state.close()
  }
}

main().catch((error) => {
  process.stderr.write(`BLOCKED: ${error.message}\n`)
  process.exitCode = 2
})
