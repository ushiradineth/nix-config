// Loaded through oc-loop's child environment only, never installed globally.
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
  if (typeof client.question?.reply !== "function" && typeof client._client?.post !== "function") {
    emit("error", { message: "The OpenCode question transport is unavailable" })
    return {}
  }
  emit("ready")
  return {
    event: async ({ event }) => {
      const request = event.properties
      if (event.type === "session.created" && sessions.has(request?.info?.parentID)) {
        sessions.add(request.info.id)
      }
      if (
        event.type !== "question.asked" ||
        !sessions.has(request?.sessionID) ||
        answered.has(request.id)
      )
        return
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
