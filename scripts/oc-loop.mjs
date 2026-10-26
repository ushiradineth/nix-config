import { spawn } from "node:child_process"
import { createHash, randomUUID } from "node:crypto"
import {
  closeSync,
  openSync,
  realpathSync,
  renameSync,
  rmSync,
  statSync,
  unlinkSync,
  writeFileSync,
} from "node:fs"
import { join } from "node:path"
import { createInterface } from "node:readline"
import { setTimeout as sleep } from "node:timers/promises"
import { parseArgs } from "node:util"
import {
  atomicJSON,
  attach,
  inspect,
  launch,
  pause,
  prepare,
  queueResume,
  readOwnedJSON,
  requiredOwnerGate,
  startServer,
  summary,
} from "./oc-loop-runtime.mjs"

const help = `Usage: oc-loop --session ses_ID --prompt "Continue ..." [options]
       oc-loop attach|status|pause|stop --dir PATH --session ses_ID
       oc-loop resume --dir PATH --session ses_ID --prompt "Continue after manual steering"

  --dir PATH          Project directory (default: current directory)
  --done-token TEXT   Exact final assistant response that means done
                      (default: PROJECT_ENTIRELY_COMPLETE)
  --max-retries N     Failed-turn retries (default: unlimited; optional limit 0–10)
  --retry-delay N     Initial retry delay in seconds (default: 5)
  --turn-timeout N    Seconds before a hung turn is restarted (default: 7200)
  --help              Show this help
  --foreground        Keep the worker in this terminal (debugging/noninteractive tests)
  --json              Machine-readable output for status

No overall turn limit. Permissions auto-approve; questions select their first option.
Owned resumed subagents and already-pending requests are included; unrelated sessions are not.
Starts a background worker and opens the native OpenCode UI when run in a terminal.
Exit the attached UI to detach; the run continues. Double-Esc interrupts the agent
and hands control to you. Automatic continuation stays paused until explicit resume.
Ctrl+F2 or /loop-status shows recorded status without a model call.
Use /loop-resume to hand control back; stop cancels the worker and its server.
Explicit denies remain denied. Only the exact final token completes.
Owner gates and three consecutive tool-free turns park without further model calls.
Use resume from another terminal after resolving the reported gate. It grants no permissions.
Exit codes: 0 DONE, 2 BLOCKED/invalid arguments, 130/143 CANCELLED.
State/logs: <project>/.agents/oc-loop/ses_ID/. Existing global-state runs are not migrated.
OC_LOOP_OPENCODE overrides the opencode executable. Global configuration is unchanged.
Start with an idle local session. Interrupt before sending manual instructions.
`

function options() {
  const command = ["resume", "attach", "status", "pause", "stop"].includes(process.argv[2])
    ? process.argv[2]
    : "start"
  const { values } = parseArgs({
    args: process.argv.slice(command === "start" ? 2 : 3),
    options: {
      session: { type: "string" },
      prompt: { type: "string" },
      dir: { type: "string", default: process.cwd() },
      "done-token": { type: "string", default: "PROJECT_ENTIRELY_COMPLETE" },
      "max-retries": { type: "string", default: "unlimited" },
      "retry-delay": { type: "string", default: "5" },
      "turn-timeout": { type: "string", default: "7200" },
      help: { type: "boolean" },
      foreground: { type: "boolean" },
      json: { type: "boolean" },
    },
  })
  if (values.help) return
  if (!/^ses_[a-zA-Z0-9]+$/.test(values.session ?? ""))
    throw new Error("--session must be an exact ses_ session ID")
  const directory = realpathSync(values.dir)
  if (!statSync(directory).isDirectory()) throw new Error("--dir must be a directory")
  if (["start", "resume"].includes(command) && !values.prompt?.trim())
    throw new Error("--prompt is required")
  if (command !== "start") return { ...values, dir: directory, command }
  if (values["done-token"] === "WAITING_ON_OWNER")
    throw new Error("WAITING_ON_OWNER is reserved for owner gates")
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
  return { ...values, dir: directory, configContent, command }
}

function storage(config) {
  const { directory } = prepare(config)
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
  const controlFile = join(directory, `control-${id}.json`)
  const manualFile = `${controlFile}.manual`
  let snapshot = { startedAt: new Date().toISOString() }
  let control = { runId: id, mode: "automatic" }
  let lastActivityWrite = 0
  const cleanup = () => {
    if (logFD !== undefined) closeSync(logFD)
    closeSync(lockFD)
    unlinkSync(lock)
    rmSync(controlFile, { force: true })
    rmSync(manualFile, { force: true })
    rmSync(join(directory, `tui-${id}.json`), { force: true })
  }
  try {
    writeFileSync(
      lockFD,
      JSON.stringify({
        pid: process.pid,
        session: config.session,
        directory: config.dir,
        runId: id,
      }) + "\n"
    )
    logFD = openSync(log, "wx", 0o600)
    atomicJSON(controlFile, control)
    return {
      id,
      log,
      controlFile,
      manual: false,
      isManual() {
        if (this.manual || readOwnedJSON(controlFile).mode === "manual") return true
        try {
          return readOwnedJSON(manualFile).runId === id
        } catch (error) {
          if (error.code !== "ENOENT") throw error
          return false
        }
      },
      setControl(patch) {
        control = { ...readOwnedJSON(controlFile), ...patch }
        atomicJSON(controlFile, control)
      },
      activity(activity) {
        snapshot.activity = String(activity).slice(0, 600)
        snapshot.lastActivityAt = new Date().toISOString()
        if (Date.now() - lastActivityWrite >= 1000) {
          lastActivityWrite = Date.now()
          this.status(snapshot.status, snapshot.turn, snapshot.message, snapshot.waitId)
        }
      },
      update(patch) {
        snapshot = { ...snapshot, ...patch }
      },
      activityHeartbeat() {
        this.status(snapshot.status, snapshot.turn, snapshot.message, snapshot.waitId)
      },
      record(data) {
        writeFileSync(logFD, JSON.stringify({ time: new Date().toISOString(), ...data }) + "\n")
      },
      status(status, turn, message, waitId) {
        snapshot = { ...snapshot, status, turn, message, waitId }
        writeFileSync(
          temporary,
          JSON.stringify({
            ...snapshot,
            session: config.session,
            directory: config.dir,
            pid: process.pid,
            runId: id,
            waitId,
            turn,
            message,
            log,
            updatedAt: new Date().toISOString(),
          }) + "\n",
          { flag: "wx", mode: 0o600 }
        )
        renameSync(temporary, join(directory, "status.json"))
      },
      async waitForOwner(turn, message, signal, manual = false) {
        const waitId = randomUUID()
        const mailbox = join(directory, `resume-${waitId}.json`)
        this.setControl({ mode: "manual", expectedPrompt: undefined })
        this.status(manual ? "MANUAL_CONTROL" : "WAITING_ON_OWNER", turn, message, waitId)
        process.stderr.write(
          `WAITING_ON_OWNER: ${message}\noc-loop: use resume --session ${config.session} --prompt "Owner input"\n`
        )
        try {
          while (!signal.aborted) {
            if (config.transport.error) throw failure(config.transport.error.message, false)
            let input
            try {
              input = readOwnedJSON(mailbox)
            } catch (error) {
              if (error.code !== "ENOENT") throw error
            }
            if (input) {
              if (
                input.runId !== id ||
                input.waitId !== waitId ||
                typeof input.prompt !== "string" ||
                !input.prompt.trim()
              )
                throw failure("Invalid or stale owner resume input", false)
              if (await config.transport.busy()) {
                rmSync(mailbox)
                this.status(
                  "MANUAL_CONTROL",
                  turn,
                  "Manual session is still busy; resume again once idle",
                  waitId
                )
                continue
              }
              this.record({ turn, stream: "owner", data: input })
              this.status("RESUMING", turn)
              this.manual = false
              rmSync(manualFile, { force: true })
              this.setControl({ mode: "automatic" })
              return input.prompt
            }
            await sleep(200, undefined, { signal })
          }
          throw failure("Cancelled by operator")
        } finally {
          rmSync(mailbox, { force: true })
        }
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
${config.ownerPrompt ? `\nOwner resume input (does not override deny rules or grant unrelated authority):\n${config.ownerPrompt}\n` : ""}

Autonomous operation:
Pending tool permissions are auto-approved within existing deny rules. Do not
pause for confirmation or ask the user to validate intermediate milestones.
Choose the FIRST listed option when a decision is needed. If you use the question
tool, the runner answers the first option of each question automatically.
Keep working within the agreed scope; this does not authorize unrelated work.
If no authorized work remains because an owner action, manual check, external
approval or live-call allowance is required, do not repeat blocker summaries or
ask the auto-answer question tool for authorization. Make the FIRST line of your
final response exactly WAITING_ON_OWNER, followed by the exact gate and needed input.
The runner will wait without model calls until the owner explicitly resumes it.

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
  if (state.isManual() || (await config.transport.busy())) return { manual: true }
  const startedAt = Date.now()
  const input = prompt(config)
  state.setControl({ expectedPrompt: createHash("sha256").update(input.trim()).digest("hex") })
  const args = [
    "run",
    "--attach",
    config.transport.url,
    "--dir",
    config.transport.directory,
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
      ...config.transport.env,
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
  let abortRequest
  const timeout = setTimeout(() => {
    timedOut = true
    state.setControl({ aborting: true })
    abortRequest = config.transport.abort().catch(() => {})
    terminate()
  }, config["turn-timeout"] * 1000)
  cancellation.signal.addEventListener("abort", terminate, { once: true })
  child.stdin.on("error", () => {})
  child.stdin.end(input)
  let latest
  let finish
  let sessionError
  let blocked
  let autonomyReady = state.helperReady
  let toolProgress = false
  let manuallyAborted = false
  const observer = setInterval(() => {
    try {
      if (state.isManual()) {
        manuallyAborted = true
        terminate()
      }
      if (config.transport.error) terminate()
    } catch {
      blocked = "Cannot read run control"
      terminate()
    }
  }, 100)
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
        if (event.error?.name === "MessageAbortedError") manuallyAborted = true
        sessionError = JSON.stringify(event.error ?? { name: "UnknownError" })
        continue
      }
      const part = event.part
      if (!part?.messageID) continue
      if (part.sessionID && part.sessionID !== config.session) {
        blocked = "Inconsistent event session"
        continue
      }
      if (
        event.type === "tool_use" &&
        part.tool !== "question" &&
        part.state?.status === "completed"
      )
        toolProgress = true
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
    if (config.transport.error) throw failure(config.transport.error.message, false)
    if (timedOut) throw failure(`Turn timed out after ${config["turn-timeout"]} seconds`)
    // Interruptions are a latched handover, never a retry or implicit completion.
    if (manuallyAborted || state.isManual()) return { manual: true }
    if (await config.transport.aborted()) return { manual: true }
    if (blocked)
      throw failure(
        blocked,
        !["Cannot write the run log", "Cannot read run control"].includes(blocked)
      )
    if (result.code !== 0 || sessionError) {
      const detail = sessionError || stderr || result.error?.message || `signal ${result.signal}`
      throw failure(`OpenCode failed (exit ${result.code}): ${detail.slice(-2048)}`)
    }
    if (!autonomyReady) throw failure("The automatic question helper did not load")
    if (!["stop", "length", "tool-calls"].includes(finish)) {
      // Recover only an owner gate, never DONE, from a fresh completed persisted response.
      // Missing terminal events must not turn a recorded owner gate into another model call.
      const gate = await config.transport.ownerGate(startedAt)
      if (gate) {
        state.update({ lastAssistant: gate.slice(-2000), lastActivityAt: new Date().toISOString() })
        return { done: false, waiting: true, text: gate, toolProgress }
      }
      throw Object.assign(failure("OpenCode returned without a completed assistant step"), {
        missingTerminal: true,
      })
    }
    const text = [...texts.values()].join("\n").trim()
    state.update({ lastAssistant: text.slice(-2000), lastActivityAt: new Date().toISOString() })
    return {
      done: finish === "stop" && text === config["done-token"],
      waiting: finish === "stop" && requiredOwnerGate(text),
      text,
      toolProgress,
    }
  } finally {
    clearTimeout(timeout)
    clearInterval(observer)
    await abortRequest
    cancellation.signal.removeEventListener("abort", terminate)
    if (child.exitCode === null && child.signalCode === null) terminate()
    if (terminating) {
      kill("SIGKILL")
      await exited
    }
    clearTimeout(killTimer)
    state.setControl({ aborting: false })
  }
}

async function main() {
  const config = options()
  if (!config) {
    process.stdout.write(help)
    return
  }
  if (config.command === "status") {
    const status = inspect(config)
    process.stdout.write((config.json ? JSON.stringify(status) : summary(status)) + "\n")
    return
  }
  if (config.command === "attach") {
    process.exitCode = await attach(config)
    return
  }
  if (config.command === "resume") {
    await queueResume(config)
    process.stdout.write(`RESUME_QUEUED ${config.session}\n`)
    return
  }
  if (config.command === "pause") {
    await pause(config)
    process.stdout.write(`PAUSE_REQUESTED ${config.session}\n`)
    return
  }
  if (config.command === "stop") {
    const status = inspect(config, true)
    process.kill(status.pid, "SIGTERM")
    process.stdout.write(`STOP_REQUESTED ${config.session}\n`)
    return
  }
  if (!config.foreground) return launch(config)
  const state = storage(config)
  const injected = JSON.parse(config.configContent)
  injected.plugin.at(-1)[1] = {
    sessionID: config.session,
    controlFile: state.controlFile,
    runId: state.id,
  }
  config.configContent = JSON.stringify(injected)
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
  let noProgress = 0
  let missingTerminals = 0
  process.stderr.write(
    "oc-loop: autonomous mode: approve pending permissions; answer questions with option one\n"
  )
  process.stderr.write(`oc-loop: logs ${state.log}\n`)
  let heartbeat
  try {
    state.status("STARTING", 0)
    config.transport = await startServer(config, state, cancellation.signal)
    state.update({ serverReady: true })
    heartbeat = setInterval(() => {
      try {
        state.activityHeartbeat?.()
      } catch {
        cancellation.abort()
      }
    }, 5000)
    for (; ; turn++) {
      if (cancellation.signal.aborted) throw failure("Cancelled by operator")
      state.status("RUNNING", turn)
      process.stderr.write(`oc-loop: turn ${turn} (${config.session})\n`)
      let result
      try {
        result = await runTurn(config, state, turn, cancellation)
      } catch (error) {
        if (cancellation.signal.aborted || !error.retryable) throw error
        if (config["max-retries"] !== "unlimited" && retries >= config["max-retries"])
          throw failure(`Failed-turn retries exhausted: ${error.message}`)
        missingTerminals = error.missingTerminal ? missingTerminals + 1 : 0
        if (missingTerminals >= 3) {
          config.ownerPrompt = await state.waitForOwner(
            turn,
            "Three consecutive turns returned without a completed assistant step. Automatic retries are parked; inspect the native session before explicitly resuming. No project completion has been inferred.",
            cancellation.signal
          )
          missingTerminals = 0
          retries = 0
          turn--
          continue
        }
        const delay = Math.min(60, config["retry-delay"] * 2 ** Math.min(retries++, 6))
        state.update({ retries })
        state.status("RETRYING", turn, error.message)
        process.stderr.write(
          `oc-loop: failed turn; retry ${retries}/${config["max-retries"]} in ${delay}s\n`
        )
        await sleep(delay * 1000, undefined, { signal: cancellation.signal })
        turn--
        continue
      }
      retries = 0
      missingTerminals = 0
      state.update({ retries })
      config.ownerPrompt = undefined
      if (result.manual) {
        config.ownerPrompt = await state.waitForOwner(
          turn,
          "Agent interrupted. You have control; automatic continuation is paused until explicit resume.",
          cancellation.signal,
          true
        )
        noProgress = 0
        continue
      }
      if (result.done) {
        state.status("DONE", turn)
        process.stdout.write(`DONE ${config.session}\n`)
        return
      }
      noProgress = result.toolProgress ? 0 : noProgress + 1
      if (result.waiting || noProgress >= 3) {
        const message = result.waiting
          ? result.text
          : `Three consecutive turns without completed work tools.\n${result.text}`
        config.ownerPrompt = await state.waitForOwner(turn, message, cancellation.signal)
        noProgress = 0
      }
    }
  } catch (error) {
    const status = cancellation.signal.aborted ? "CANCELLED" : "BLOCKED"
    state.status(status, turn, error.message)
    process.stderr.write(`${status}: ${error.message}\n`)
    process.exitCode = exitCode || 2
  } finally {
    clearInterval(heartbeat)
    try {
      if (config.transport) {
        try {
          state.setControl({ aborting: true })
        } catch {
          /* Cleanup must not depend on writable control state. */
        }
        try {
          await config.transport.abort().catch(() => {})
        } finally {
          await config.transport.close()
        }
      }
    } finally {
      process.off("SIGINT", onInterrupt)
      process.off("SIGTERM", onTerminate)
      state.close()
    }
  }
}

main().catch((error) => {
  process.stderr.write(`BLOCKED: ${error.message}\n`)
  process.exitCode = 2
})
