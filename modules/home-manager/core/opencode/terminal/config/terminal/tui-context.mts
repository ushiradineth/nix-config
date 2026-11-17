import { createTerminalContext, rootTransition, terminalEventData } from "./terminal-context.mts"
import type { AttentionEvent, RootState, TerminalEvent } from "./terminal-context.mts"

interface Session {
  id: string
  parentID?: string
  title?: string
  outcome?: "succeeded" | "failed" | "interrupted"
}

// The subset of @opencode/plugin/tui Context used here, verified against 2.2.5.
// All process/terminal state belongs to this TUI, even with a remote server.
export interface TuiContext {
  location?: { directory: string }
  data: {
    location: { default(): { directory: string } }
    listen(handler: (event: { details: TerminalEvent }) => void): () => void
    session: {
      get(id: string): Session | undefined
      status(id: string): "idle" | "running"
      sync(id: string): Promise<void>
      permission: {
        list(id: string): { id: string }[] | undefined
        sync(id: string): Promise<void>
      }
      form: { list(id: string): { id: string }[] | undefined; sync(id: string): Promise<void> }
    }
  }
  ui: { router: { current(): { type: string; sessionID?: string } } }
}

type TerminalContext = Pick<
  ReturnType<typeof createTerminalContext>,
  "ownedTUI" | "refresh" | "register" | "addRoot" | "updateRoot" | "capture" | "notify" | "release"
>

export function attachTerminalContext(
  tui: TuiContext,
  terminal: TerminalContext = createTerminalContext({
    directory: (tui.location ?? tui.data.location.default()).directory,
  }),
  options: { notifications?: boolean; observeSelection?: (changed: () => void) => () => void } = {}
) {
  if (!terminal.ownedTUI()) return
  try {
    terminal.refresh()
  } catch {}
  let owner: string | undefined
  let selected: string | undefined
  let disposed = false
  let queue = Promise.resolve()
  const roots = new Map<string, RootState>()
  const seen = new Set<string>()
  const selectedID = () => {
    const route = tui.ui.router.current()
    return route.type === "session" ? route.sessionID : undefined
  }
  const enqueue = (action: () => Promise<void>) => {
    queue = queue.then(() => (disposed ? undefined : action())).catch(() => {})
    return queue
  }

  function invalidateSelection() {
    const id = selectedID()
    if (selected && selected !== id && owner) {
      const previous = roots.get(selected)!
      roots.set(selected, { ...previous, active: false })
      if (!previous.deleted) terminal.updateRoot(owner, selected, { active: false })
      selected = undefined
    }
  }

  async function select(reconnect = false) {
    invalidateSelection()
    const id = selectedID()
    if (id === selected && !reconnect) return
    if (!id) return
    let timeout: ReturnType<typeof setTimeout> | undefined
    try {
      await Promise.race([
        Promise.all([
          tui.data.session.sync(id),
          tui.data.session.permission.sync(id),
          tui.data.session.form.sync(id),
        ]),
        new Promise<never>((_, reject) => {
          timeout = setTimeout(() => reject(new Error("Session synchronization timed out")), 2000)
        }),
      ])
    } finally {
      clearTimeout(timeout)
    }
    if (disposed || selectedID() !== id) return
    const session = tui.data.session.get(id)
    // Viewing a child never claims its parent or any other conversation.
    if (!session || session.parentID || session.id !== id) return
    if (!owner) owner = await terminal.register(id)
    terminal.addRoot(owner, id, session.title)
    const permissions = tui.data.session.permission.list(id) ?? []
    const pending = [...permissions, ...(tui.data.session.form.list(id) ?? [])].map(
      (request) => request.id
    )
    const prior = roots.get(id)
    const root: RootState = {
      id,
      title: session.title ?? "",
      active: true,
      pending,
      cancelled: session.outcome === "interrupted",
      status: pending.length
        ? "needs_input"
        : tui.data.session.status(id) === "running"
          ? "working"
          : session.outcome === "failed"
            ? "error"
            : session.outcome === "succeeded"
              ? "done"
              : "idle",
    }
    roots.set(id, root)
    terminal.updateRoot(
      owner,
      id,
      root,
      !!prior && prior.status !== "working" && root.status === "working"
    )
    selected = id
    if (pending.length && (!prior || prior.pending.join() !== pending.join())) {
      // Rebuild inbox state for an existing request after attach/reconnect;
      // opening a conversation must not replay its native notification.
      await terminal.capture({
        owner,
        sessionID: id,
        event: permissions.length ? "permission" : "question",
        title: root.title,
      })
    }
  }

  async function event(event: TerminalEvent) {
    await select(event.type === "server.connected")
    if (!selected || !owner) return
    if (event.id) {
      if (seen.has(event.id)) return
      seen.add(event.id)
      if (seen.size > 2048) seen.delete(seen.values().next().value!)
    }
    const root = roots.get(selected)!
    const next = rootTransition(root, event)
    const data = terminalEventData(event)
    const belongs = (data.form?.sessionID ?? data.sessionID) === root.id
    if (
      next === root &&
      !(
        belongs &&
        [
          "session.execution.started",
          "session.execution.succeeded",
          "session.execution.failed",
          "permission.asked",
          "form.created",
        ].includes(event.type)
      )
    )
      return
    roots.set(root.id, next)
    terminal.updateRoot(owner, root.id, next, event.type === "session.execution.started")
    const attention: AttentionEvent | undefined =
      event.type === "permission.asked"
        ? "permission"
        : event.type === "form.created"
          ? "question"
          : event.type === "session.execution.succeeded"
            ? "complete"
            : event.type === "session.execution.failed"
              ? "error"
              : undefined
    if (!attention) return
    const token = await terminal.capture({
      owner,
      sessionID: root.id,
      event: attention,
      title: next.title,
    })
    if (options.notifications ?? process.platform === "darwin") await terminal.notify(token)
  }

  const stop = tui.data.listen(({ details }) => {
    void enqueue(() => event(details))
  })
  const stopSelection = options.observeSelection?.(() => {
    // Synchronous route invalidation precedes asynchronous session loading and
    // prevents notification callbacks from using the conversation we just left.
    invalidateSelection()
    void enqueue(() => select())
  })
  void enqueue(() => select())
  return async () => {
    disposed = true
    stopSelection?.()
    stop()
    await queue
    try {
      if (owner) terminal.release(owner)
    } catch {}
  }
}
