import { createHash } from "node:crypto"
import { atomicJSON, readOwnedJSON } from "./oc-loop-runtime.mjs"

// Loaded through oc-loop's server environment only, never installed globally.
export default async function autonomy({ client, directory }, options = {}) {
  const sessionID = options.sessionID
  if (!sessionID) return {}
  const sessions = new Set([sessionID])
  const answered = new Set()
  const resolving = new Map()
  const replying = new Map()
  const emit = (status, data = {}) => {
    process.stdout.write(
      JSON.stringify({ type: "oc_loop_autonomy", sessionID, status, ...data }) + "\n"
    )
  }
  const control = () => {
    if (!options.controlFile) return { mode: "automatic" }
    const state = readOwnedJSON(options.controlFile)
    if (state.runId !== options.runId) throw new Error("Stale oc-loop control state")
    try {
      const manual = readOwnedJSON(`${options.controlFile}.manual`)
      if (manual.runId !== options.runId) throw new Error("Stale oc-loop takeover state")
      return { ...state, mode: "manual" }
    } catch (error) {
      if (error.code !== "ENOENT") throw error
    }
    return state
  }
  const handover = () => {
    const state = control()
    if (state.aborting || state.mode === "manual") return
    if (options.controlFile) {
      // Separate, one-way latch: an in-flight worker write cannot undo takeover.
      atomicJSON(`${options.controlFile}.manual`, { runId: options.runId })
      atomicJSON(options.controlFile, { ...state, mode: "manual", expectedPrompt: undefined })
    }
    emit("manual")
  }
  const automatic = () => {
    const state = control()
    return state.mode === "automatic" && !state.aborting
  }
  const get = async (url, path = {}) => {
    if (typeof client._client?.get !== "function")
      throw new Error("Owned-session lookup is unavailable")
    const response = await client._client.get({
      url,
      path,
      query: { directory },
      throwOnError: true,
    })
    if (response.error) throw new Error("Owned-session lookup failed")
    return response.data
  }
  const owns = async (id) => {
    if (sessions.has(id)) return true
    if (typeof id !== "string" || !/^ses_[A-Za-z0-9]+$/.test(id)) return false
    if (resolving.has(id)) return resolving.get(id)
    const pending = (async () => {
      const visited = new Set()
      let current = id
      while (current && !visited.has(current) && visited.size < 64) {
        if (sessions.has(current)) {
          for (const owned of visited) sessions.add(owned)
          return true
        }
        visited.add(current)
        const info = await get("/session/{sessionID}", { sessionID: current })
        if (info?.id !== current) return false
        current = info.parentID
      }
      return false
    })()
    resolving.set(id, pending)
    try {
      return await pending
    } finally {
      resolving.delete(id)
    }
  }
  const answer = async (kind, request) => {
    const key = `${kind}:${request.id}`
    if (!automatic() || answered.has(key)) return
    if (replying.has(key)) return replying.get(key)
    const pending = (async () => {
      if (!(await owns(request.sessionID)) || !automatic()) return
      try {
        const answers =
          kind === "question"
            ? request.questions.map((question) => [
                question.options?.[0]?.label ||
                  "Use your best judgment within the agreed scope and continue.",
              ])
            : undefined
        if (!automatic()) return
        if (kind === "question" && typeof client.question?.reply === "function") {
          await client.question.reply(
            { requestID: request.id, directory, answers },
            { throwOnError: true }
          )
        } else {
          // The pinned legacy SDK lacks question methods. Its bound transport
          // preserves in-process fetch/auth and the native instance directory.
          const response = await client._client.post({
            url: `/${kind}/{requestID}/reply`,
            path: { requestID: request.id },
            query: { directory },
            body: kind === "permission" ? { reply: "once" } : { answers },
            bodySerializer: JSON.stringify,
            headers: { "Content-Type": "application/json" },
            throwOnError: true,
          })
          if (response.error) throw new Error("Automatic reply failed")
        }
        answered.add(key)
        emit(kind === "question" ? "answered" : "permission-approved", {
          requestID: request.id,
          ownedSessionID: request.sessionID,
          ...(answers ? { answers } : {}),
        })
      } catch {
        // Native --auto may have answered the same request first. A request that
        // disappeared is resolved, not a helper failure or a reason to reapprove.
        try {
          const pending = await get(`/${kind}`)
          if (Array.isArray(pending) && !pending.some((item) => item.id === request.id)) {
            answered.add(key)
            return
          }
        } catch {
          /* Keep the actual unresolved reply failure visible. */
        }
        if (automatic())
          emit("error", {
            requestID: request.id,
            message: `Could not automatically answer the ${kind}`,
          })
      }
    })()
    replying.set(key, pending)
    try {
      await pending
    } finally {
      replying.delete(key)
    }
  }
  const reconcile = async () => {
    if (!automatic()) return
    try {
      const [permissions, questions] = await Promise.all([get("/permission"), get("/question")])
      if (!Array.isArray(permissions) || !Array.isArray(questions))
        throw new Error("Invalid pending request list")
      for (const request of permissions) await answer("permission", request)
      for (const request of questions) await answer("question", request)
    } catch {
      if (automatic())
        emit("error", { message: "Could not reconcile pending owned-session requests" })
    }
  }
  if (typeof client.question?.reply !== "function" && typeof client._client?.post !== "function") {
    emit("error", { message: "The OpenCode question transport is unavailable" })
    return {}
  }
  emit("ready")
  return {
    "chat.message": async (input, output) => {
      if (!options.controlFile || input.sessionID !== sessionID) return
      const state = control()
      const text = output.parts
        .filter((part) => part.type === "text")
        .map((part) => part.text)
        .join("\n")
        .trim()
      const digest = createHash("sha256").update(text).digest("hex")
      if (state.mode === "automatic" && state.expectedPrompt === digest) {
        atomicJSON(options.controlFile, { ...state, expectedPrompt: undefined })
        // Do this after instance initialization, not while loading the plugin:
        // startup and resumed turns can inherit requests with no new asked event.
        await reconcile()
      } else handover()
    },
    event: async ({ event }) => {
      const request = event.properties
      if (event.type === "session.created" && sessions.has(request?.info?.parentID)) {
        sessions.add(request.info.id)
      }
      if (
        (event.type === "session.error" &&
          request?.sessionID === sessionID &&
          request.error?.name === "MessageAbortedError") ||
        (event.type === "message.updated" &&
          request?.info?.sessionID === sessionID &&
          request.info.error?.name === "MessageAbortedError")
      )
        handover()
      if (
        request?.part?.sessionID &&
        event.type === "message.part.updated" &&
        request.part.type === "tool" &&
        (sessions.has(request.part.sessionID) ||
          (automatic() && (await owns(request.part.sessionID).catch(() => false))))
      ) {
        const part = request.part
        emit("activity", {
          activity: `${part.sessionID === sessionID ? "" : "Subagent · "}${part.tool}: ${part.state?.status} ${part.state?.title || ""}`,
        })
      }
      try {
        if (event.type === "question.asked") await answer("question", request)
        if (event.type === "permission.asked") await answer("permission", request)
      } catch {
        if (automatic()) emit("error", { message: "Could not verify automatic request ownership" })
      }
    },
  }
}
