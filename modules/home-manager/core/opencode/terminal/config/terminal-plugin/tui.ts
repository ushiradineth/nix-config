import { createComputed } from "solid-js"
import { attachTerminalContext } from "../terminal/tui-context.mts"
import type { TuiContext } from "../terminal/tui-context.mts"

interface PluginContext extends TuiContext {
  ui: TuiContext["ui"] & {
    slot(claim: { append: "app"; render(): null }): () => void
  }
}

export function observeTerminalSelection(tui: PluginContext, changed: () => void) {
  return tui.ui.slot({
    append: "app",
    render() {
      createComputed(changed)
      return null
    },
  })
}

export default {
  id: "opencode-terminal-context",
  setup(tui: PluginContext) {
    return attachTerminalContext(tui, undefined, {
      observeSelection: (changed) => observeTerminalSelection(tui, changed),
    })
  },
}
