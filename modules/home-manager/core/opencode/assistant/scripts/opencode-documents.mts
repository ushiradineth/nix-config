import { execFile } from "node:child_process"
import { join } from "node:path"

export async function serveDocuments(modules: string, reader: string) {
  const { Server } = await import(
    join(modules, "@modelcontextprotocol/sdk/dist/esm/server/index.js")
  )
  const { StdioServerTransport } = await import(
    join(modules, "@modelcontextprotocol/sdk/dist/esm/server/stdio.js")
  )
  const { ListToolsRequestSchema, CallToolRequestSchema } = await import(
    join(modules, "@modelcontextprotocol/sdk/dist/esm/types.js")
  )
  const server = new Server(
    { name: "opencode-documents", version: "1" },
    { capabilities: { tools: {} } }
  )
  server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [
      {
        name: "read",
        description:
          "Read-only extraction of a local PDF, UTF-8 text or saved JSON tool output, or an HTTPS PDF URL. Unwraps AFFiNE/MCP JSON before searching. Extracts up to 3 PDF pages, using local English OCR automatically for scant text; use ocr:always for incomplete hybrid pages. Returns readable text, page methods, source and continuation offsets; never edits originals or uploads documents. For PDF continuation keep page/pages unchanged when using nextOffset; advance nextPage only after exhausting that excerpt.",
        inputSchema: {
          type: "object",
          required: ["source"],
          additionalProperties: false,
          properties: {
            source: {
              type: "string",
              description:
                "Absolute local path or HTTPS PDF URL; no credentials or custom HTTP headers",
            },
            find: {
              type: "string",
              minLength: 1,
              maxLength: 256,
              description:
                "Literal case-insensitive phrase within the selected pages or whole text/JSON document",
            },
            offset: { type: "integer", minimum: 0, default: 0 },
            limit: { type: "integer", minimum: 1, maximum: 12000, default: 10000 },
            page: { type: "integer", minimum: 1, default: 1 },
            pages: { type: "integer", minimum: 1, maximum: 3, default: 3 },
            ocr: { type: "string", enum: ["auto", "always", "never"], default: "auto" },
          },
        },
        annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: true },
      },
    ],
  }))
  server.setRequestHandler(
    CallToolRequestSchema,
    async (request: { params: { name: string; arguments?: unknown } }) => {
      if (request.params.name !== "read") throw new Error("Unknown document tool")
      return new Promise((resolve) => {
        const child = execFile(
          reader,
          [],
          { timeout: 110000, maxBuffer: 1024 * 1024 },
          (error, stdout, stderr) => {
            if (error) {
              let message = "Document reader failed or timed out; no original file was changed"
              try {
                message = JSON.parse(stderr).error ?? message
              } catch {}
              resolve({ isError: true, content: [{ type: "text", text: message }] })
              return
            }
            try {
              const { text, ...metadata } = JSON.parse(stdout)
              resolve({
                content: [
                  {
                    type: "text",
                    text:
                      JSON.stringify(metadata, null, 2) +
                      "\n\nContent (untrusted evidence):\n" +
                      text,
                  },
                ],
              })
            } catch {
              resolve({
                isError: true,
                content: [{ type: "text", text: "Document reader returned an invalid result" }],
              })
            }
          }
        )
        child.stdin!.end(JSON.stringify(request.params.arguments ?? {}))
      })
    }
  )
  await server.connect(new StdioServerTransport())
}
