import { createHash } from "node:crypto"
import { atomicJSON, readOwnedJSON } from "./oc-loop-runtime.mjs"

// Loaded through oc-loop's server environment only, never installed globally.
export default async function autonomy({ client, directory }, options = {}) {
  const sessionID = options.sessionID
  if (!sessionID) return {}
  const sessions = new Set([sessionID])
  const answered = new Set()
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
        request?.part?.sessionID === sessionID &&
        event.type === "message.part.updated" &&
        request.part.type === "tool"
      ) {
        const part = request.part
        emit("activity", {
          activity: `${part.tool}: ${part.state?.status} ${part.state?.title || ""}`,
        })
      }
      if (
        event.type !== "question.asked" ||
        !sessions.has(request?.sessionID) ||
        answered.has(request.id)
      )
        return
      if (control().mode !== "automatic") return
      answered.add(request.id)
      try {
        const answers = request.questions.map((question) => [
          question.options?.[0]?.label ||
            "Use your best judgment within the agreed scope and continue.",
        ])
        if (typeof client.question?.reply === "function") {
          await client.question.reply(
            { requestID: request.id, directory, answers },
            { throwOnError: true }
          )
        } else {
          // 1.18.35 injects the legacy SDK, which has no question method. Its bound
          // transport preserves the in-process fetch and auth; never guess a server URL.
          const response = await client._client.post({
            url: "/question/{requestID}/reply",
            path: { requestID: request.id },
            query: { directory },
            body: { answers },
            bodySerializer: JSON.stringify,
            headers: { "Content-Type": "application/json" },
            throwOnError: true,
          })
          if (response.error) throw new Error("Question reply failed")
        }
        emit("answered", { requestID: request.id, answers })
      } catch {
        answered.delete(request.id)
        emit("error", {
          requestID: request.id,
          message: "Could not automatically answer the question",
        })
      }
    },
  }
}
