import { create, edit, read, type Context } from "../../tools/obsidian"

interface ToolContext {
  sessionID: string
  agent: string
  messageID: string
  id: string
}

interface Definition<Input> {
  description: string
  args: Record<string, unknown>
  execute(input: Input, context: Context): Promise<string>
}

interface Editor {
  add<Input>(tool: {
    name: string
    description: string
    input: Record<string, unknown>
    options: { codemode: false }
    execute(input: Input, context: ToolContext): Promise<{ content: string }>
  }): void
}

interface PluginContext {
  tool: { transform(callback: (editor: Editor) => void): Promise<unknown> }
  permission: {
    assert(input: {
      sessionID: string
      agent: string
      action: string
      resources: string[]
      save: string[]
      metadata: Record<string, unknown>
      source: { type: "tool"; messageID: string; id: string }
    }): Promise<void>
  }
}

export default {
  id: "local.obsidian",
  async setup(ctx: PluginContext) {
    await ctx.tool.transform((editor) => {
      function register<Input>(name: string, definition: Definition<Input>) {
        editor.add({
          name: `obsidian_${name}`,
          description: definition.description,
          input: {
            type: "object",
            properties: definition.args,
            required: Object.keys(definition.args),
            additionalProperties: false,
          },
          options: { codemode: false },
          async execute(input: Input, context) {
            const content = await definition.execute(input, {
              ask: ({ permission, patterns, always, metadata }) =>
                ctx.permission.assert({
                  sessionID: context.sessionID,
                  agent: context.agent,
                  action: permission,
                  resources: patterns,
                  save: always,
                  metadata,
                  source: { type: "tool", messageID: context.messageID, id: context.id },
                }),
            })
            return { content }
          },
        })
      }
      register("read", read)
      register("create", create)
      register("edit", edit)
    })
  },
}
