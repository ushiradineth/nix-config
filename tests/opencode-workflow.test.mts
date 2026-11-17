import assert from "node:assert/strict"
import { spawn, spawnSync } from "node:child_process"
import { once } from "node:events"
import {
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs"
import { createServer } from "node:http"
import { tmpdir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { setTimeout as delay } from "node:timers/promises"
import { fileURLToPath } from "node:url"
import test from "node:test"

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..")
const configRoot = join(root, "modules/home-manager/core/opencode/config")
const config = JSON.parse(readFileSync(join(configRoot, "opencode.json"), "utf8"))
const binary = process.env.OPENCODE_TEST_BINARY ?? "opencode"
const leaves = ["general", "explore", "reviewer"]
const gmailReads = [
  "search_gmail_messages",
  "get_gmail_message_content",
  "get_gmail_messages_content_batch",
  "get_gmail_thread_content",
  "get_gmail_threads_content_batch",
  "get_gmail_attachment_content",
  "list_gmail_labels",
]
const googleDenied = [
  "send_gmail_message",
  "draft_gmail_message",
  "modify_gmail_message_labels",
  "batch_modify_gmail_message_labels",
  "manage_gmail_label",
  "manage_gmail_filter",
  "list_events",
  "search_drive_files",
  "a_future_tool",
]
const mockTools: Record<string, string[]> = {
  actualbudget: ["actual_get_context"],
  documents: ["read"],
  google: [...gmailReads, ...googleDenied],
}

interface Session {
  id: string
  agent: string
}
interface Message {
  type: string
  content?: { type: string; state?: { status: string; error?: unknown } }[]
}
interface ConfigEntry {
  type: string
  info?: { default_agent: string; agents: Record<string, { system: string }> }
}
interface McpServer {
  name: string
  status: { status: string }
}
interface Discovery {
  id: string
  name: string
}
interface Data<T> {
  data: T
}

interface Agent {
  id: string
  name: string
  mode: string
  system?: string
  model?: unknown
}
interface ChatRequest {
  tools?: { function: { name: string } }[]
  messages: { role: string; content: string | unknown[] }[]
}

async function fixture(candidate = config, mockMcp = false) {
  const dir = realpathSync(mkdtempSync(join(tmpdir(), "opencode-workflow-")))
  const home = join(dir, "home")
  const workspace = join(home, "Code/workspace")
  const installed = join(home, ".config/opencode")
  mkdirSync(workspace, { recursive: true })
  mkdirSync(installed, { recursive: true })
  for (const entry of ["prompts", "instructions", "skills", "commands", "tools"])
    cpSync(join(configRoot, entry), join(installed, entry), { recursive: true })
  cpSync(join(configRoot, "plugins/obsidian"), join(installed, "plugins/obsidian"), {
    recursive: true,
  })
  const mock = join(dir, "mcp.mts")
  writeFileSync(
    mock,
    `
    import { createInterface } from "node:readline";
    const tools = JSON.parse(process.argv[2]);
    for await (const line of createInterface({ input: process.stdin })) {
      const request = JSON.parse(line);
      if (request.id === undefined) continue;
      const result = request.method === "initialize"
        ? { protocolVersion: "2024-11-05", capabilities: { tools: {} }, serverInfo: { name: "fixture", version: "1" } }
        : request.method === "tools/list"
          ? { tools: tools.map(name => ({ name, description: "Fixture tool", inputSchema: { type: "object", properties: {} } })) }
          : request.method === "tools/call"
            ? { content: [{ type: "text", text: "verified-fixture-read" }] }
            : {};
      process.stdout.write(JSON.stringify({ jsonrpc: "2.0", id: request.id, result }) + String.fromCharCode(10));
    }
  `
  )
  const requests: ChatRequest[] = []
  // Drive the packaged agent loop without an account, remote model, or host credentials.
  const model = createServer(async (request, response) => {
    let body = ""
    for await (const chunk of request) body += chunk
    const input: ChatRequest = JSON.parse(body)
    requests.push(input)
    const user = input.messages.findLast((message) => message.role === "user")
    const text = typeof user?.content === "string" ? user.content : JSON.stringify(user?.content)
    const selected = /fixture-tool:(\{[^\n]+\})/.exec(text ?? "")
    const call = selected && !input.messages.some((message) => message.role === "tool")
    const tool = call ? JSON.parse(selected[1]) : undefined
    response.writeHead(200, { "content-type": "text/event-stream" })
    for (const [delta, finish] of [
      [
        call
          ? {
              role: "assistant",
              tool_calls: [
                {
                  index: 0,
                  id: "call_fixture",
                  type: "function",
                  function: { name: tool.name, arguments: JSON.stringify(tool.args) },
                },
              ],
            }
          : { role: "assistant", content: "fixture complete" },
        null,
      ],
      [{}, call ? "tool_calls" : "stop"],
    ])
      response.write(
        `data: ${JSON.stringify({
          id: "chatcmpl-fixture",
          object: "chat.completion.chunk",
          created: 1,
          model: "chat",
          choices: [{ index: 0, delta, finish_reason: finish }],
        })}\n\n`
      )
    response.end("data: [DONE]\n\n")
  })
  model.listen(0, "127.0.0.1")
  await once(model, "listening")
  const address = model.address()
  assert.ok(address && typeof address !== "string")
  const servers = Object.fromEntries(
    Object.keys(candidate.mcp.servers).map((name) => [
      name,
      {
        type: "local",
        disabled: !mockMcp,
        command: [process.execPath, mock, JSON.stringify(mockTools[name])],
      },
    ])
  )
  const installedConfig = {
    ...candidate,
    model: "fixture/chat",
    providers: {
      fixture: {
        package: "@opencode/ai/providers/openai/chat",
        settings: { baseURL: `http://127.0.0.1:${address.port}/v1`, apiKey: "fixture" },
        models: { chat: {} },
      },
    },
    agents: { ...candidate.agents, title: { disabled: true } },
    mcp: { servers },
    plugins: [],
  }
  const configFile = join(installed, "opencode.json")
  writeFileSync(configFile, JSON.stringify(installedConfig))
  const env = {
    PATH: process.env.PATH,
    HOME: home,
    TMPDIR: dir,
    XDG_CONFIG_HOME: join(home, ".config"),
    XDG_DATA_HOME: join(home, ".local/share"),
    XDG_STATE_HOME: join(home, ".local/state"),
    XDG_CACHE_HOME: join(home, ".cache"),
    CI: "true",
    GIT_TERMINAL_PROMPT: "0",
    GIT_CONFIG_NOSYSTEM: "1",
  }
  const init = spawnSync("git", ["init", "--quiet", workspace], {
    env,
    encoding: "utf8",
    timeout: 20000,
  })
  assert.ifError(init.error)
  assert.equal(init.status, 0, init.stderr)
  const child = spawn(binary, ["serve", "--hostname", "127.0.0.1", "--port", "0"], {
    cwd: workspace,
    env,
    stdio: ["ignore", "pipe", "pipe"],
  })
  let startup = ""
  let stderr = ""
  let spawnError: Error | undefined
  child.stdout.on("data", (chunk) => (startup += chunk))
  child.stderr.on("data", (chunk) => (stderr += chunk))
  child.on("error", (error) => (spawnError = error))
  async function close() {
    if (child.exitCode === null && child.signalCode === null) {
      const exited = once(child, "exit")
      child.kill()
      await exited
    }
    await new Promise<void>((done) => model.close(() => done()))
    rmSync(dir, { recursive: true, force: true })
  }
  try {
    const deadline = Date.now() + 20000
    while (!/server password (\S+)/.test(startup)) {
      assert.ifError(spawnError)
      assert.equal(child.exitCode, null, stderr)
      assert.ok(Date.now() < deadline, `server startup timed out: ${stderr}`)
      await delay(25)
    }
    const url = /server listening on (http:\/\/\S+)/.exec(startup)![1]
    const password = /server password (\S+)/.exec(startup)![1]
    async function request(path: string, body?: object) {
      const response = await fetch(`${url}${path}`, {
        method: body ? "POST" : "GET",
        headers: {
          authorization: `Basic ${Buffer.from(`opencode:${password}`).toString("base64")}`,
          "content-type": "application/json",
        },
        body: body ? JSON.stringify(body) : undefined,
        signal: AbortSignal.timeout(20000),
      })
      const text = await response.text()
      return { status: response.status, body: text ? (JSON.parse(text) as unknown) : null }
    }
    async function api<T = Data<Session>>(path: string, body?: object): Promise<T> {
      const response = await request(path, body)
      assert.ok(
        response.status === 200 || response.status === 204,
        `${path}: ${JSON.stringify(response.body)}`
      )
      return response.body as T
    }
    const agents: Agent[] = (await api<Data<Agent[]>>("/api/agent")).data
    const sessions = new Map<string, string>()
    async function session(agent: string) {
      const created = await api("/api/session", {
        agent,
        title: "Workflow fixture",
        model: { providerID: "fixture", id: "chat" },
        location: { directory: workspace },
      })
      return created.data.id as string
    }
    return {
      home,
      workspace,
      configFile,
      installedConfig,
      agents,
      session,
      api,
      request,
      async action(agent: string, action: string, resource = "*") {
        let id = sessions.get(agent)
        if (!id) {
          id = await session(agent)
          sessions.set(agent, id)
        }
        const result = await api<Data<{ effect: string }>>(`/api/session/${id}/permission`, {
          action,
          resources: [resource],
          agent,
        })
        return result.data.effect as string
      },
      async tool(name: string, args: object, agent = "assistant") {
        const start = requests.length
        const id = await session(agent)
        await api(`/api/session/${id}/prompt`, {
          text: `fixture-tool:${JSON.stringify({ name, args })}`,
        })
        const deadline = Date.now() + 20000
        let messages: Message[] = []
        while (true) {
          messages = (await api<Data<Message[]>>(`/api/session/${id}/message`)).data
          if (messages.some((message) => message.type === "idle")) break
          assert.ok(Date.now() < deadline, `tool ${name} timed out: ${JSON.stringify(messages)}`)
          await delay(25)
        }
        const calls = requests.slice(start)
        return {
          messages,
          errors: messages
            .flatMap((message) => message.content ?? [])
            .filter((content) => content.type === "tool" && content.state?.status === "error")
            .map((content) => content.state!.error),
          requests: calls,
          output: calls.flatMap((input) =>
            input.messages
              .filter((message) => message.role === "tool")
              .map((message) => message.content)
          ),
        }
      },
      run(args: string[]) {
        return spawnSync(binary, ["api", "--standalone", ...args], {
          cwd: workspace,
          env,
          timeout: 20000,
          encoding: "utf8",
        })
      },
      close,
    }
  } catch (error) {
    await close()
    throw error
  }
}

type Fixture = Awaited<ReturnType<typeof fixture>>
function resolved(f: Fixture, id: string) {
  const agent = f.agents.find((agent) => agent.id === id)
  assert.ok(agent, `${id} is registered`)
  return agent
}
async function assertCoordinator(f: Fixture) {
  assert.equal(resolved(f, "jiyu").mode, "primary")
  assert.equal(await f.action("jiyu", "subagent", "jiyu"), "deny")
  for (const leaf of [...leaves, "assistant"])
    assert.equal(await f.action("jiyu", "subagent", leaf), "allow", leaf)
}
async function assertLeaf(f: Fixture, id: string) {
  assert.equal(resolved(f, id).mode, "subagent")
  assert.equal(await f.action(id, "subagent", "general"), "deny", "workers cannot delegate")
  if (id !== "general") assert.equal(await f.action(id, "edit"), "deny", "review is read-only")
}

test("V2 resolves the default coordinator and enforces bounded workers natively", async () => {
  const f = await fixture()
  try {
    const documents = await f.api<ConfigEntry[]>("/api/config")
    assert.ok(Array.isArray(documents))
    assert.equal(documents.find((entry) => entry.type === "document")!.info!.default_agent, "jiyu")
    await assertCoordinator(f)
    for (const name of leaves) {
      await assertLeaf(f, name)
      assert.equal(resolved(f, name).model, undefined, "role models inherit")
    }
  } finally {
    await f.close()
  }
})

test("sudo-jiyu shares Jiyu guidance and permits every tool and resource", async () => {
  const f = await fixture()
  try {
    assert.equal(resolved(f, "sudo-jiyu").system, resolved(f, "jiyu").system)
    for (const [action, resource] of [
      ["shell", "sudo command"],
      ["shell", "rm file"],
      ["shell", "git push"],
      ["shell", "just build"],
      ["external_directory", "/unfamiliar/path/file"],
      ["read", "private.env"],
      ["edit", "/unfamiliar/path/file"],
      ["subagent", "sudo-jiyu"],
      ["skill", "personal-assistant"],
      ["doom_loop", "*"],
      ["actualbudget_actual_get_context", "*"],
      ["documents_read", "*"],
      ["obsidian_read", "*"],
      ["obsidian_create", "*"],
      ["obsidian_edit", "*"],
      ["google_send_gmail_message", "*"],
      ["a_future_plugin_tool", "*"],
    ])
      assert.equal(await f.action("sudo-jiyu", action, resource), "allow", `${action}: ${resource}`)
  } finally {
    await f.close()
  }
})

test("ordinary checks run while destructive commands and external paths retain approval", async () => {
  const f = await fixture()
  try {
    for (const command of [
      "rg retry src",
      "git diff --cached",
      "just check",
      "just build-dry",
      "pnpm test",
    ])
      assert.equal(await f.action("jiyu", "shell", command), "allow", command)
    for (const command of [
      "git push",
      "git reset --hard",
      "git clean -fd",
      "rm file",
      "sudo command",
      "gh pr merge 123",
      "just build",
      "just deploy shu",
      "darwin-rebuild switch",
    ])
      assert.equal(await f.action("jiyu", "shell", command), "ask", command)
    assert.equal(await f.action("jiyu", "external_directory", "/unfamiliar/path/file"), "ask")
    assert.equal(await f.action("jiyu", "external_directory", join(f.workspace, "file")), "allow")
    for (const prefix of ["/var/folders", "/private/var/folders"]) {
      const temp = `${prefix}/ab/a-different-temp-id/T`
      assert.equal(
        await f.action("jiyu", "external_directory", `${temp}/opencode/output.txt`),
        "allow"
      )
      for (const path of [`${temp}/other/file`, `${temp}/opencode-other/file`])
        assert.equal(await f.action("jiyu", "external_directory", path), "ask", path)
    }
  } finally {
    await f.close()
  }
})

test("native MCP transports connect and personal services belong to the assistant", async () => {
  const f = await fixture(config, true)
  try {
    assert.equal(resolved(f, "assistant").mode, "all")
    for (const [action, resource] of [
      ["subagent", "general"],
      ["edit", "*"],
      ["shell", "echo fixture"],
      ["ctx_execute", "*"],
      ["a_future_plugin_tool", "*"],
      ["documents_execute", "*"],
      ["documents_write", "*"],
    ])
      assert.equal(await f.action("assistant", action, resource), "deny", action)
    assert.equal(await f.action("assistant", "read"), "allow")
    assert.equal(await f.action("assistant", "skill", "personal-assistant"), "allow")
    let servers = (await f.api<Data<McpServer[]>>("/api/mcp")).data
    const deadline = Date.now() + 15000
    while (servers.some((server: McpServer) => server.status.status === "pending")) {
      assert.ok(Date.now() < deadline, JSON.stringify(servers))
      await delay(50)
      servers = (await f.api<Data<McpServer[]>>("/api/mcp")).data
    }
    for (const name of Object.keys(mockTools)) {
      const server = servers.find((entry: McpServer) => entry.name === name)
      assert.ok(server, `${name} transport is registered`)
      assert.equal(server.status.status, "connected", JSON.stringify(server))
    }
    for (const tool of ["actualbudget_actual_get_context", "documents_read"]) {
      assert.equal(await f.action("assistant", tool), "allow")
      for (const name of ["jiyu", ...leaves]) assert.equal(await f.action(name, tool), "deny")
      let result = await f.tool(tool, {})
      // MCP connection readiness precedes its debounced tool registration.
      const ready = Date.now() + 15000
      while (!result.requests[0].tools!.some((entry) => entry.function.name === tool)) {
        assert.ok(Date.now() < ready, `${tool} was not registered`)
        await delay(25)
        result = await f.tool(tool, {})
      }
      assert.deepEqual(result.errors, [])
      assert.deepEqual(result.output, ["verified-fixture-read"])
      const exposed = result.requests[0].tools!.map((entry) => entry.function.name)
      for (const denied of ["documents_write", "documents_execute", "google_send_gmail_message"])
        assert.equal(exposed.includes(denied), false, `${denied} is unavailable to the assistant`)
    }
  } finally {
    await f.close()
  }
})

test("mail read permissions belong to the assistant and all writes stay denied", async () => {
  const f = await fixture()
  try {
    for (const name of gmailReads) {
      const tool = `google_${name}`
      assert.equal(await f.action("assistant", tool), "allow", tool)
      for (const agent of ["jiyu", ...leaves])
        assert.equal(await f.action(agent, tool), "deny", `${agent}: ${tool}`)
    }
    for (const name of googleDenied)
      assert.equal(await f.action("assistant", `google_${name}`), "deny", name)
  } finally {
    await f.close()
  }
})

test("native discovery loads skills and their command entrypoints", async () => {
  const f = await fixture()
  try {
    const names = new Set(
      (await f.api<Data<Discovery[]>>("/api/skill")).data.map((skill: Discovery) => skill.id)
    )
    assert.ok(names.has("personal-assistant"))
    const commands = (await f.api<Data<Discovery[]>>("/api/command")).data
    assert.ok(commands.some((command: Discovery) => command.name === "assistant"))
    const id = await f.session("jiyu")
    await f.api(`/api/session/${id}/command`, { name: "assistant", text: "fixture" })
    assert.equal((await f.api(`/api/session/${id}`)).data.agent, "assistant")
    for (const name of [
      "jiyu-mode",
      "jiyu-help",
      "impeccable",
      "benchmark-checklist",
      "blast-radius",
      "in-your-own-words",
      "how",
      "figure-it-out",
      "ketchup",
      "interrogate",
      "swarm",
      "unslop",
      "typescript-best-practices",
      "no-comments",
      "loop-on-ci",
      "fix-merge-conflicts",
      "thermo-nuclear-code-quality-review",
    ]) {
      assert.ok(names.has(name), `${name} is discoverable`)
      assert.ok(commands.some((command: Discovery) => command.name === name))
      await f.api(`/api/session/${id}/command`, { name, text: "fixture" })
      assert.equal(
        (await f.api(`/api/session/${id}`)).data.agent,
        "jiyu",
        `/${name} uses the primary session`
      )
    }
    for (const name of ["engineering-quality", "brainstorming", "handoff", "humanizer"])
      assert.equal(names.has(name), false, `${name} is retired`)
  } finally {
    await f.close()
  }
})

test("native V2 tools permit implementation and reject reviewer and explorer writes", async () => {
  const f = await fixture()
  try {
    for (const agent of ["jiyu", "general", "reviewer", "explore", "assistant"]) {
      const file = join(f.workspace, `${agent}-product.txt`)
      const result = await f.tool("write", { path: file, content: "fixture\n" }, agent)
      if (agent === "jiyu" || agent === "general") {
        assert.ok(existsSync(file), JSON.stringify(result.messages))
        assert.equal(readFileSync(file, "utf8"), "fixture\n")
        const tools = result.requests[0].tools!.map((tool) => tool.function.name)
        if (agent === "jiyu") {
          assert.ok(tools.includes("subagent"))
          assert.ok(tools.includes("shell"))
          assert.ok(tools.includes("todowrite"))
          assert.equal(tools.includes("task"), false)
          assert.equal(tools.includes("bash"), false)
        }
      } else {
        assert.equal(existsSync(file), false, `${agent} cannot write`)
        assert.match(
          JSON.stringify(result.messages),
          /denied|not found|not available|no tool named|invalid tool|unknown tool/i
        )
      }
    }
    const receipt = join(f.workspace, ".agents/reviewer-note.md")
    await f.tool("write", { path: receipt, content: "denied" }, "reviewer")
    assert.equal(existsSync(receipt), false, "shared state has no reviewer write exception")
  } finally {
    await f.close()
  }
})

test("assistant uses native Obsidian tools with revision and path safeguards", async () => {
  const f = await fixture()
  try {
    const vault = join(f.home, "Documents/Obsidian Vault")
    mkdirSync(vault, { recursive: true })
    const note = join(vault, "Review.md")
    writeFileSync(note, "# Review\n\nExisting paragraph.\n")
    const read = async (path: string, offset = 0, limit = 12000) => {
      const result = await f.tool("obsidian_read", { path, offset, limit })
      assert.ok(result.output.length, JSON.stringify(result.messages))
      return JSON.parse(result.output[0] as string)
    }
    const original = await read("Review.md")
    assert.equal(original.text, readFileSync(note, "utf8"))
    const edit = {
      path: "Review.md",
      expectedRevision: original.revision,
      oldText: "Existing paragraph.",
      newText: "Existing paragraph.\n\nRequested next steps.",
    }
    await f.tool("obsidian_edit", edit)
    assert.equal(
      readFileSync(note, "utf8"),
      "# Review\n\nExisting paragraph.\n\nRequested next steps.\n"
    )
    const stale = await f.tool("obsidian_edit", edit)
    assert.match(JSON.stringify(stale.errors), /changed|revision/i)
    const current = await read("Review.md")
    const ambiguous = await f.tool("obsidian_edit", {
      ...edit,
      expectedRevision: current.revision,
      oldText: "\n",
      newText: "ambiguous",
    })
    assert.match(JSON.stringify(ambiguous.errors), /exactly one/i)
    assert.equal(readFileSync(note, "utf8"), current.text)
    const page = await read("Review.md", 2, 6)
    assert.equal(page.text, current.text.slice(2, 8))
    assert.equal(page.nextOffset, 8)
    writeFileSync(join(vault, "Empty.md"), "")
    const empty = await read("Empty.md")
    await f.tool("obsidian_edit", {
      path: "Empty.md",
      expectedRevision: empty.revision,
      oldText: "",
      newText: "First entry.\n",
    })
    assert.equal(readFileSync(join(vault, "Empty.md"), "utf8"), "First entry.\n")
    const create = { path: "Projects/Weekly review.md", markdown: "# Weekly review\n" }
    await f.tool("obsidian_create", create)
    assert.equal(readFileSync(join(vault, create.path), "utf8"), create.markdown)
    await f.tool("obsidian_create", { ...create, markdown: "must not overwrite" })
    assert.equal(readFileSync(join(vault, create.path), "utf8"), create.markdown)
    for (const path of [
      "../outside.md",
      "/tmp/outside.md",
      "settings.json",
      ".obsidian/config.md",
      "Notes/.selfsync/credentials.md",
    ]) {
      const result = await f.tool("obsidian_create", { path, markdown: "must not be written" })
      assert.match(JSON.stringify(result.errors), /relative|hidden|traversal|\.md/i, path)
    }
    symlinkSync(f.workspace, join(vault, "linked"))
    await f.tool("obsidian_create", { path: "linked/escape.md", markdown: "denied" })
    assert.equal(existsSync(join(f.workspace, "escape.md")), false)
    symlinkSync(note, join(vault, "alias.md"))
    const alias = await f.tool("obsidian_read", { path: "alias.md", offset: 0, limit: 12000 })
    assert.match(JSON.stringify(alias.errors), /symbolic|symlink|regular/i)
    for (const agent of ["jiyu", ...leaves]) {
      await f.tool("obsidian_create", { path: `${agent}.md`, markdown: "denied" }, agent)
      assert.equal(existsSync(join(vault, `${agent}.md`)), false, agent)
    }
  } finally {
    await f.close()
  }
})

test("native permission evaluation catches candidate regressions", async () => {
  for (const [agent, rule, check] of [
    ["jiyu", { action: "subagent", resource: "*", effect: "allow" }, assertCoordinator],
    [
      "reviewer",
      { action: "edit", resource: "*", effect: "allow" },
      (f: Fixture) => assertLeaf(f, "reviewer"),
    ],
    [
      "general",
      { action: "subagent", resource: "*", effect: "allow" },
      (f: Fixture) => assertLeaf(f, "general"),
    ],
  ] as const) {
    const invalid = structuredClone(config)
    invalid.agents[agent].permissions = [...(invalid.agents[agent].permissions ?? []), rule]
    const f = await fixture(invalid)
    try {
      await assert.rejects(() => check(f))
    } finally {
      await f.close()
    }
  }
})

test("validation detects documents and guidance silently omitted by the V2 loader", async () => {
  const f = await fixture()
  try {
    writeFileSync(f.configFile, "{broken")
    const syntax = f.run(["GET", "/api/config"])
    assert.ifError(syntax.error)
    assert.equal(syntax.status, 0, syntax.stderr)
    assert.equal(
      (JSON.parse(syntax.stdout) as ConfigEntry[]).some((entry) => entry.type === "document"),
      false
    )
    const invalid = structuredClone(f.installedConfig)
    invalid.agents.jiyu.system = "{file:./prompts/missing-fixture.md}"
    writeFileSync(f.configFile, JSON.stringify(invalid))
    const missing = f.run(["GET", "/api/config"])
    assert.ifError(missing.error)
    assert.equal(missing.status, 0, missing.stderr)
    const document = (JSON.parse(missing.stdout) as ConfigEntry[]).find(
      (entry) => entry.type === "document"
    )!
    assert.equal(
      document.info!.agents.jiyu.system,
      "",
      "missing prompt must fail nonempty-guidance validation"
    )
  } finally {
    await f.close()
  }
})
