import autonomy from "../scripts/oc-loop-autonomy.mjs"
import type { AutonomyContext, AutonomyEvent } from "../scripts/oc-loop-autonomy.mjs"

export default async function (ctx: AutonomyContext) {
  return {
    event: async (input: { event: AutonomyEvent }) => {
      const event = input.event
      if (event.type !== "question.asked" && event.type !== "permission.asked") return
      const hooks = await autonomy(ctx, { sessionID: event.properties.sessionID })
      await hooks.event(input)
    },
  }
}
