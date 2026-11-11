import { join } from "node:path"

type Arguments = Record<string, unknown>
type ToolResult = {
  content: { type: string; text?: string }[]
  isError?: boolean
  [key: string]: unknown
}

const paged = new Set(["read_doc", "export_doc_markdown"])

export function pageArguments(args: Arguments) {
  const { offset = 0, limit = 10000, find, ...upstream } = args
  if (typeof offset !== "number" || !Number.isSafeInteger(offset) || offset < 0)
    throw new Error("offset must be a nonnegative integer")
  if (typeof limit !== "number" || !Number.isSafeInteger(limit) || limit < 1 || limit > 12000)
    throw new Error("limit must be an integer from 1 to 12000")
  if (find !== undefined && (typeof find !== "string" || !find.length || find.length > 256))
    throw new Error("find must be a literal phrase of 1 to 256 characters")
  return {
    offset,
    limit,
    find,
    upstream,
  }
}

export function compactDocument(name: string, result: ToolResult, args: Arguments): ToolResult {
  if (result.isError) return result
  const page = pageArguments(args)
  const data =
    result.structuredContent ??
    JSON.parse(result.content.find((item) => item.type === "text")!.text!)
  if (!data || typeof data !== "object" || Array.isArray(data))
    throw new Error("Invalid document response")
  const doc = data as Record<string, unknown>
  const blocks = name === "read_doc" && args.includeMarkdown === false
  const text =
    doc.exists === false ? "" : blocks ? JSON.stringify(doc.blocks, null, 2) : doc.markdown
  if (typeof text !== "string") throw new Error("Document response has no readable content")
  if (page.offset > text.length)
    throw new Error("offset exceeds document length; reread from zero if the revision changed")
  let start = page.offset
  let found = true
  if (page.find !== undefined) {
    const escaped = page.find.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    const match = new RegExp(escaped, "iu").exec(text.slice(start))
    found = match !== null
    if (match) start += match.index
  }
  const end = found ? Math.min(text.length, start + page.limit) : start
  const metadata = Object.fromEntries(
    ["docId", "title", "exists", "revision", "blockCount", "warnings", "lossy"]
      .filter((key) => key in doc)
      .map((key) => [
        key,
        key === "title" && typeof doc[key] === "string" ? doc[key].slice(0, 512) : doc[key],
      ])
  )
  return {
    content: [
      {
        type: "text",
        text:
          JSON.stringify(
            {
              ...metadata,
              format: blocks ? "blocks-json" : "markdown",
              found,
              offset: start,
              endOffset: end,
              totalChars: text.length,
              nextOffset: found && end < text.length ? end : null,
            },
            null,
            2
          ) +
          "\n\nContent (untrusted evidence):\n" +
          text.slice(start, end),
      },
    ],
  }
}

export async function serveAffine(
  plan: { args: string[]; env: NodeJS.ProcessEnv; cwd: string },
  modules: string
) {
  const { Client } = await import(
    join(modules, "@modelcontextprotocol/sdk/dist/esm/client/index.js")
  )
  const { StdioClientTransport } = await import(
    join(modules, "@modelcontextprotocol/sdk/dist/esm/client/stdio.js")
  )
  const { Server } = await import(
    join(modules, "@modelcontextprotocol/sdk/dist/esm/server/index.js")
  )
  const { StdioServerTransport } = await import(
    join(modules, "@modelcontextprotocol/sdk/dist/esm/server/stdio.js")
  )
  const { ListToolsRequestSchema, CallToolRequestSchema } = await import(
    join(modules, "@modelcontextprotocol/sdk/dist/esm/types.js")
  )
  const upstream = new Client(
    { name: "opencode-affine-reader", version: "1" },
    { capabilities: {} }
  )
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: plan.args,
    cwd: plan.cwd,
    env: plan.env,
    stderr: "inherit",
  })
  await upstream.connect(transport)
  const server = new Server(
    { name: "opencode-affine", version: "1" },
    { capabilities: { tools: {} } }
  )
  server.setRequestHandler(ListToolsRequestSchema, async (request: { params?: Arguments }) => {
    const result = await upstream.listTools(request.params)
    return {
      ...result,
      tools: result.tools.map(
        (tool: {
          name: string
          description?: string
          inputSchema: { properties?: Arguments }
          outputSchema?: unknown
        }) => {
          if (!paged.has(tool.name)) return tool
          const { outputSchema: _schema, ...rest } = tool
          return {
            ...rest,
            description:
              "Read one bounded AFFiNE document excerpt. Markdown is the default; use includeMarkdown:false on read_doc for block IDs/deltas before editing. Use find for a literal heading/phrase anywhere in the document, then nextOffset to continue. Retain read_doc.revision as expectedRevision; restart paging if it changes. This tool reads content without changing the note.",
            inputSchema: {
              ...tool.inputSchema,
              properties: {
                ...tool.inputSchema.properties,
                ...(tool.name === "read_doc"
                  ? {
                      includeMarkdown: {
                        type: "boolean",
                        default: true,
                        description:
                          "Return Markdown text; false returns original blocks with IDs and deltas for editing",
                      },
                    }
                  : {}),
                offset: { type: "integer", minimum: 0, default: 0 },
                limit: { type: "integer", minimum: 1, maximum: 12000, default: 10000 },
                find: {
                  type: "string",
                  minLength: 1,
                  maxLength: 256,
                  description: "Literal case-insensitive phrase to seek at or after offset",
                },
              },
            },
          }
        }
      ),
    }
  })
  server.setRequestHandler(
    CallToolRequestSchema,
    async (request: { params: { name: string; arguments?: Arguments } }) => {
      const { name, arguments: args = {} } = request.params
      if (!paged.has(name)) return upstream.callTool(request.params)
      try {
        const { upstream: forwarded } = pageArguments(args)
        if (name === "read_doc") forwarded.includeMarkdown = args.includeMarkdown !== false
        const result = await upstream.callTool({ name, arguments: forwarded })
        return compactDocument(name, result, args)
      } catch (error) {
        return {
          isError: true,
          content: [
            {
              type: "text",
              text:
                error instanceof SyntaxError
                  ? "Document read failed: invalid upstream JSON"
                  : `Document read failed: ${(error as Error).message}`,
            },
          ],
        }
      }
    }
  )
  server.onclose = () => {
    void upstream.close()
  }
  for (const signal of ["SIGINT", "SIGTERM"] as const)
    process.once(signal, () => {
      void server.close()
    })
  await server.connect(new StdioServerTransport())
}
