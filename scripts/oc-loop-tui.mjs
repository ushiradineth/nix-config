import { inspect, queueResume, summary } from "./oc-loop-runtime.mjs"

// Native TUI extension API, pinned against OpenCode v1.18.35. No server hooks here.
export default {
  id: "oc-loop-controls",
  tui: async (api, options) => {
    const config = { dir: options.directory, session: options.session }
    const check = () => {
      if (
        api.route.current.name !== "session" ||
        api.route.current.params?.sessionID !== config.session
      )
        throw new Error("Switch back to the oc-loop session to use its controls")
      const status = inspect(config)
      if (status.runId !== options.runId) throw new Error("This attachment belongs to an older run")
      return status
    }
    const show = (title, message) =>
      api.ui.dialog.replace(() => api.ui.DialogAlert({ title, message }))
    const dispose = api.keymap.registerLayer({
      commands: [
        {
          namespace: "palette",
          name: "oc-loop.status",
          title: "Show loop status",
          category: "oc-loop",
          slashName: "loop-status",
          run() {
            try {
              show("oc-loop status", summary(check()))
            } catch (error) {
              show("oc-loop", error.message)
            }
          },
        },
        {
          namespace: "palette",
          name: "oc-loop.resume",
          title: "Hand control back to loop",
          category: "oc-loop",
          slashName: "loop-resume",
          async run() {
            try {
              check()
              await queueResume({
                ...config,
                prompt:
                  "Continue the entire agreed project after my manual steering. Respect the updated session instructions and existing approval boundaries.",
              })
              show(
                "oc-loop",
                "Resume queued. Automatic continuation will use your updated session context."
              )
            } catch (error) {
              show("oc-loop", error.message)
            }
          },
        },
      ],
      bindings: [{ key: "ctrl+f2", cmd: "oc-loop.status", desc: "Show loop status" }],
    })
    api.lifecycle.onDispose(dispose)
  },
}
