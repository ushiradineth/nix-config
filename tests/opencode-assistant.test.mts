import assert from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { chmod, mkdtemp, readFile, rm, stat, symlink, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { createRequire } from "node:module"
import { PassThrough } from "node:stream"
import test from "node:test"
import {
  credentialPath,
  launchPlan,
  readCredentials,
  readSecret,
  saveCredentials,
} from "../scripts/opencode-assistant.mts"

async function fixture(t: test.TestContext) {
  const root = await mkdtemp(join(tmpdir(), "opencode-assistant-"))
  t.after(() => rm(root, { recursive: true, force: true }))
  return {
    root,
    env: {
      HOME: root,
      XDG_CONFIG_HOME: join(root, "config"),
      XDG_DATA_HOME: join(root, "data"),
      OPENCODE_ASSISTANT_MODULES: "/packaged/node_modules",
    },
  }
}

const actual = {
  ACTUAL_SERVER_URL: "https://budget.example.com",
  ACTUAL_PASSWORD: "a password with $() and `literal` text",
  ACTUAL_BUDGET_SYNC_ID: "selected-personal-budget",
}
const affine = {
  AFFINE_BASE_URL: "https://notes.example.com",
  AFFINE_EMAIL: "me@example.com",
  AFFINE_PASSWORD: "private-affine-password",
  AFFINE_WORKSPACE_ID: "selected-personal-workspace",
}

test("hidden input preserves password bytes alongside ANSI keys and restores terminal state", async () => {
  class Input extends PassThrough {
    isRaw = false
    setRawMode(raw: boolean) {
      this.isRaw = raw
      return this
    }
  }
  const input = new Input()
  const first = readSecret(input)
  input.write("fixture-password\u001b[D\r")
  assert.equal(await first, "fixture-password")
  assert.equal(input.isRaw, false)
  assert.equal(input.listenerCount("keypress"), 0)
  const second = readSecret(input)
  input.write("encryptez\u007fd\r")
  assert.equal(await second, "encrypted")
  const cancelled = readSecret(input)
  input.write("\u0003")
  await assert.rejects(cancelled, /cancelled/)
  assert.equal(input.isRaw, false)
  input.destroy()
})

test("credentials round-trip privately and values are never shell-expanded", async (t) => {
  const f = await fixture(t)
  await saveCredentials("actualbudget", actual, f.env)
  const path = credentialPath("actualbudget", f.env)
  assert.equal((await stat(path)).mode & 0o777, 0o600)
  assert.equal((await stat(join(f.env.XDG_CONFIG_HOME, "opencode-assistant"))).mode & 0o777, 0o700)
  assert.deepEqual(await readCredentials("actualbudget", f.env), actual)
  const changed = { ...actual, ACTUAL_PASSWORD: "replacement" }
  await saveCredentials("actualbudget", changed, f.env)
  assert.deepEqual(await readCredentials("actualbudget", f.env), changed)
})

test("invalid credentials, public permissions and symlinks fail without leaking values", async (t) => {
  const f = await fixture(t)
  await assert.rejects(readCredentials("actualbudget", f.env), /setup actualbudget/)
  await assert.rejects(
    saveCredentials("actualbudget", { ...actual, NODE_OPTIONS: "injection" }, f.env),
    /Unsupported/
  )
  await assert.rejects(
    saveCredentials("actualbudget", { ...actual, ACTUAL_PASSWORD: "" }, f.env),
    /ACTUAL_PASSWORD/
  )
  await assert.rejects(
    saveCredentials(
      "actualbudget",
      { ...actual, ACTUAL_SERVER_URL: "https://user:secret@example.com" },
      f.env
    ),
    (error: Error) => {
      assert.doesNotMatch(error.message, /user:secret/)
      return true
    }
  )
  await saveCredentials("actualbudget", actual, f.env)
  const path = credentialPath("actualbudget", f.env)
  await chmod(path, 0o644)
  await assert.rejects(readCredentials("actualbudget", f.env), /0600/)
  await chmod(path, 0o600)
  await writeFile(path, '{"ACTUAL_PASSWORD":"private-syntax-error"')
  await assert.rejects(readCredentials("actualbudget", f.env), (error: Error) => {
    assert.doesNotMatch(error.message, /private-syntax-error/)
    return /Invalid credential JSON/.test(error.message)
  })
  await rm(path)
  const target = join(f.root, "outside.json")
  await writeFile(target, JSON.stringify(actual), { mode: 0o600 })
  await symlink(target, path)
  await assert.rejects(readCredentials("actualbudget", f.env))
  await assert.rejects(saveCredentials("actualbudget", actual, f.env), /symbolic link/)
  assert.deepEqual(JSON.parse(await readFile(target, "utf8")), actual)
})

test("budget launch stays read-only and replaces ambient connector settings", async (t) => {
  const f = await fixture(t)
  await saveCredentials("actualbudget", actual, f.env)
  const plan = await launchPlan("actualbudget", {
    ...f.env,
    MCP_READ_ONLY: "false",
    MCP_TOOLS: "actual_transactions_delete",
    ACTUAL_BUDGET_REGISTRY: "unexpected-budget",
    BUDGET_1_NAME: "Default",
    BUDGET_1_SYNC_ID: "unexpected-budget",
    AFFINE_COOKIE: "other-service-secret",
    UNRELATED_API_TOKEN: "unrelated-secret",
    NODE_OPTIONS: "--import=untrusted",
  })
  assert.equal(plan.env.MCP_READ_ONLY, "true")
  assert.equal(plan.env.ACTUAL_BUDGET_SYNC_ID, actual.ACTUAL_BUDGET_SYNC_ID)
  assert.equal(plan.env.ACTUAL_PASSWORD, actual.ACTUAL_PASSWORD)
  assert.equal(plan.env.ACTUAL_BUDGET_REGISTRY, undefined)
  assert.equal(plan.env.BUDGET_1_SYNC_ID, undefined)
  assert.equal(plan.env.AFFINE_COOKIE, undefined)
  assert.equal(plan.env.UNRELATED_API_TOKEN, undefined)
  assert.equal(plan.env.NODE_OPTIONS, undefined)
  assert.doesNotMatch(plan.env.MCP_TOOLS ?? "", /delete/)
  assert.deepEqual(plan.args, [
    "/packaged/node_modules/actual-mcp-server/bin/actual-mcp-server.js",
    "--stdio",
  ])
  assert.ok(plan.cwd.startsWith(f.env.XDG_DATA_HOME))
  assert.equal(plan.env.MCP_BRIDGE_DATA_DIR, join(plan.cwd, "cache"))
  assert.equal((await stat(plan.env.MCP_BRIDGE_DATA_DIR!)).mode & 0o777, 0o700)
  assert.equal((await stat(plan.cwd)).mode & 0o777, 0o700)
  await writeFile(join(plan.cwd, ".env"), "BUDGET_1_SYNC_ID=unexpected-budget\n")
  await assert.rejects(launchPlan("actualbudget", f.env), /Unexpected .env/)
})

test("AFFiNE uses the selected workspace and incremental authoring without account or sharing tools", async (t) => {
  const f = await fixture(t)
  await saveCredentials("affine", affine, f.env)
  const plan = await launchPlan("affine", {
    ...f.env,
    AFFINE_TOOL_PROFILE: "full",
    MCP_TRANSPORT: "http",
  })
  assert.equal(plan.env.AFFINE_WORKSPACE_ID, affine.AFFINE_WORKSPACE_ID)
  assert.equal(plan.env.AFFINE_TOOL_PROFILE, "core")
  assert.equal(plan.env.MCP_TRANSPORT, "stdio")
  assert.equal(plan.env.AFFINE_CLIENT_VERSION, "0.27.4")
  assert.match(plan.env.AFFINE_DISABLED_GROUPS ?? "", /destructive/)
  assert.match(plan.env.AFFINE_DISABLED_GROUPS ?? "", /docs.share/)
  assert.match(plan.env.AFFINE_DISABLED_TOOLS ?? "", /sign_in/)
  assert.equal(plan.env.ACTUAL_PASSWORD, undefined)
  assert.equal(plan.env.XDG_CONFIG_HOME, join(plan.cwd, "config"))
})

test(
  "the packaged CLI reports configuration without claiming a working connection",
  { skip: !process.env.OPENCODE_ASSISTANT_TEST_BINARY },
  async (t) => {
    const f = await fixture(t)
    const binary = process.env.OPENCODE_ASSISTANT_TEST_BINARY!
    await saveCredentials("actualbudget", actual, f.env)
    const status = spawnSync(binary, ["status"], {
      env: { ...process.env, ...f.env },
      encoding: "utf8",
    })
    assert.equal(status.status, 0, status.stderr)
    assert.match(status.stdout, /actualbudget: configured/)
    assert.match(status.stdout, /affine: not configured/)
    assert.match(status.stdout, /not checked/)
    assert.doesNotMatch(status.stdout + status.stderr, /a password|private-affine-password/)
    const missing = spawnSync(binary, ["run", "affine"], {
      env: { ...process.env, ...f.env },
      encoding: "utf8",
    })
    assert.notEqual(missing.status, 0)
    assert.equal(missing.stdout, "", "MCP stdout stays free of diagnostics")
    assert.match(missing.stderr, /setup affine/)
  }
)

const modules = process.env.OPENCODE_ASSISTANT_TEST_MODULES
test(
  "packaged document MCP extracts a large saved response without credentials or execution tools",
  { skip: !modules, timeout: 20000 },
  async (t) => {
    const f = await fixture(t)
    const source = join(f.root, "saved-output.json")
    const original = JSON.stringify({
      markdown: "old notes ".repeat(10000) + "START HERE\nConfirmed 123.45",
      revision: "a".repeat(64),
    })
    await writeFile(source, original)
    const { Client } = await import(
      join(modules!, "@modelcontextprotocol/sdk/dist/esm/client/index.js")
    )
    const { StdioClientTransport } = await import(
      join(modules!, "@modelcontextprotocol/sdk/dist/esm/client/stdio.js")
    )
    const client = new Client({ name: "document-check", version: "1" }, { capabilities: {} })
    const transport = new StdioClientTransport({
      command: process.env.OPENCODE_ASSISTANT_TEST_BINARY!,
      args: ["run", "documents"],
      env: { ...process.env, ...f.env },
      stderr: "pipe",
    })
    try {
      await client.connect(transport)
      const catalog = await client.listTools()
      assert.deepEqual(
        catalog.tools.map((tool: { name: string }) => tool.name),
        ["read"]
      )
      assert.equal(catalog.tools[0].annotations.readOnlyHint, true)
      const result = await client.callTool({
        name: "read",
        arguments: { source, find: "START HERE" },
      })
      assert.equal(result.isError, undefined, JSON.stringify(result.content))
      assert.ok(result.content[0].text.endsWith("START HERE\nConfirmed 123.45"))
      assert.ok(result.content[0].text.length < 1000)
      const refused = await client.callTool({
        name: "read",
        arguments: { source, command: "touch unauthorized" },
      })
      assert.equal(refused.isError, true)
      assert.equal(await readFile(source, "utf8"), original)
    } finally {
      await transport.close()
    }
  }
)

test("the packaged Actual SQLite dependency can execute queries", { skip: !modules }, () => {
  const require = createRequire(join(modules!, "package.json"))
  const Database = require("better-sqlite3")
  const database = new Database(":memory:")
  try {
    assert.equal(database.prepare("select 42 as value").get().value, 42)
  } finally {
    database.close()
  }
})

test(
  "real packaged MCP servers publish the intended surfaces and refuse excluded writes",
  { skip: !modules, timeout: 20000 },
  async (t) => {
    const f = await fixture(t)
    const { Client } = await import(
      join(modules!, "@modelcontextprotocol/sdk/dist/esm/client/index.js")
    )
    const { StdioClientTransport } = await import(
      join(modules!, "@modelcontextprotocol/sdk/dist/esm/client/stdio.js")
    )
    await saveCredentials(
      "actualbudget",
      { ...actual, ACTUAL_SERVER_URL: "http://127.0.0.1:9" },
      f.env
    )
    await saveCredentials("affine", { ...affine, AFFINE_BASE_URL: "http://127.0.0.1:9" }, f.env)
    for (const service of ["actualbudget", "affine"] as const) {
      const client = new Client(
        { name: "opencode-assistant-check", version: "1" },
        { capabilities: {} }
      )
      const transport = new StdioClientTransport({
        command: process.env.OPENCODE_ASSISTANT_TEST_BINARY!,
        args: ["run", service],
        env: { ...process.env, ...f.env },
        stderr: "pipe",
      })
      try {
        await client.connect(transport)
        const tools = await client.listTools()
        const names = new Set(tools.tools.map((tool: { name: string }) => tool.name))
        const expected =
          service === "actualbudget"
            ? [
                "actual_get_context",
                "actual_query_run",
                "actual_budgets_getMonth",
                "actual_schedules_get",
              ]
            : ["read_doc", "create_doc_from_markdown", "append_markdown", "update_block"]
        for (const name of expected) assert.ok(names.has(name), `${service}: ${name}`)
        const excluded =
          service === "actualbudget"
            ? ["actual_transactions_create", "actual_bank_sync", "actual_budgets_switch"]
            : [
                "replace_doc_with_markdown",
                "publish_doc",
                "delete_doc",
                "sign_in",
                "update_workspace",
              ]
        for (const name of excluded) assert.equal(names.has(name), false, `${service}: ${name}`)
        assert.ok(names.size <= 32, `${service} keeps a bounded tool surface`)
        const refused = await client
          .callTool({ name: excluded[0], arguments: {} })
          .catch((error: Error) => ({ isError: true, message: error.message }))
        assert.equal(refused.isError, true, `${service} refuses a hidden write`)
      } finally {
        await transport.close()
      }
    }
  }
)
