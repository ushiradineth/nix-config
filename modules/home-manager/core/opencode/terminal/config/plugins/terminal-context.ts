import { createTerminalContext, rootTransition } from "../terminal/terminal-context.mts"
import type { RootState, TerminalEvent } from "../terminal/terminal-context.mts"

interface PluginInput {
  directory: string
  client: {
    session: {
      get(input: {
        path: { id: string }
      }): Promise<{ data?: { id: string; title: string; parentID?: string | null } }>
    }
  }
}

export default async function terminalContext({ client, directory }: PluginInput) {
  const context = createTerminalContext({ directory })
  if (!context.ownedTUI()) return {}
  try {
    context.refresh()
  } catch {}
  delete process.env.OPENCODE_TERMINAL_OWNER
  let root: RootState | undefined, owner: string | undefined
  let queue = Promise.resolve()
  const enqueue = (action: () => Promise<void>) => {
    queue = queue.then(action).catch(() => {})
    return queue
  }
  async function activate(id: string, newTurn: boolean): Promise<void> {
    let timer: ReturnType<typeof setTimeout> | undefined
    let response: Awaited<ReturnType<PluginInput["client"]["session"]["get"]>>
    try {
      response = await Promise.race([
        client.session.get({ path: { id } }),
        new Promise<never>((_, reject) => {
          timer = setTimeout(() => reject(new Error("Session lookup timed out")), 1500)
        }),
      ])
    } finally {
      clearTimeout(timer)
    }
    const data = response?.data
    if (!data || data.parentID || data.id !== id) return
    if (!owner) owner = await context.register(data.id)
    context.addRoot(owner, data.id, data.title)
    process.env.OPENCODE_TERMINAL_OWNER = owner
    root = {
      id: data.id,
      title: data.title,
      status: newTurn ? "working" : "idle",
      pending: [],
      cancelled: false,
    }
    context.updateRoot(owner, root.id, root, newTurn)
  }
  try {
    const id = context.initialRoot()
    if (id) await activate(id, false)
  } catch {}
  return {
    "chat.message"(input: { sessionID?: string }) {
      return enqueue(async () => {
        if (!input.sessionID) return
        await activate(input.sessionID, true)
      })
    },
    event({ event }: { event: TerminalEvent }) {
      return enqueue(async () => {
        if (!root || !owner) return
        const next = rootTransition(root, event)
        if (next === root) return
        root = next
        context.updateRoot(owner, root.id, root)
      })
    },
    async dispose() {
      await queue
      try {
        if (owner) context.release(owner)
      } catch {}
      if (process.env.OPENCODE_TERMINAL_OWNER === owner) delete process.env.OPENCODE_TERMINAL_OWNER
    },
  }
}
