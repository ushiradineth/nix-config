import assert from "node:assert/strict"
import { spawnSync } from "node:child_process"
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  realpathSync,
  rmSync,
  writeFileSync,
} from "node:fs"
import { tmpdir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import test from "node:test"

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..")
const configRoot = join(root, "modules/home-manager/core/opencode/config")
const config = JSON.parse(readFileSync(join(configRoot, "opencode.json"), "utf8"))
const primaries = ["planner", "builder", "direct", "sudo"]
const leaves = ["explore", "general", "audit", "grind", "ideate", "writer"]
const binary = process.env.OPENCODE_TEST_BINARY ?? "opencode"

interface Rule {
  permission: string
  pattern: string
  action: string
}
interface ResolvedAgent {
  name: string
  mode: string
  permission: Rule[]
  steps?: number
  temperature?: number
  model?: unknown
  tools: Record<string, boolean>
}

function fixture(candidate = config) {
  const dir = realpathSync(mkdtempSync(join(tmpdir(), "opencode-workflow-")))
  const home = join(dir, "home")
  const workspace = join(home, "Code/workspace")
  const installed = join(home, ".config/opencode")
  mkdirSync(workspace, { recursive: true })
  mkdirSync(join(installed, "prompts"), { recursive: true })
  mkdirSync(join(installed, "instructions"))
  for (const file of readdirSync(join(configRoot, "prompts")))
    copyFileSync(join(configRoot, "prompts", file), join(installed, "prompts", file))
  copyFileSync(join(configRoot, "instructions/shell.md"), join(installed, "instructions/shell.md"))
  writeFileSync(join(installed, "opencode.json"), JSON.stringify(candidate))
  const env = {
    PATH: process.env.PATH,
    HOME: home,
    TMPDIR: dir,
    XDG_CONFIG_HOME: join(home, ".config"),
    XDG_DATA_HOME: join(home, ".local/share"),
    XDG_STATE_HOME: join(home, ".local/state"),
    XDG_CACHE_HOME: join(home, ".cache"),
    OPENCODE_DISABLE_PROJECT_CONFIG: "1",
    OPENCODE_DISABLE_EXTERNAL_SKILLS: "1",
    OPENCODE_DISABLE_CLAUDE_CODE_SKILLS: "1",
    OPENCODE_DISABLE_MODELS_FETCH: "1",
    OPENCODE_DISABLE_DEFAULT_PLUGINS: "1",
    OPENCODE_PURE: "1",
    CI: "true",
    GIT_TERMINAL_PROMPT: "0",
    GIT_CONFIG_NOSYSTEM: "1",
  }
  // Native edit patterns are relative to the detected worktree. A non-Git
  // directory uses a different root and cannot test repository state permissions.
  const init = spawnSync("git", ["init", "--quiet", workspace], {
    env,
    encoding: "utf8",
    timeout: 20000,
  })
  assert.ifError(init.error)
  assert.equal(init.status, 0, init.stderr)
  return {
    workspace,
    configFile: join(installed, "opencode.json"),
    run(args: string[]) {
      const result = spawnSync(binary, ["--pure", ...args], {
        cwd: workspace,
        env,
        encoding: "utf8",
        timeout: 20000,
        maxBuffer: 2 * 1024 * 1024,
      })
      assert.ifError(result.error)
      assert.notEqual(result.status, null, "native diagnostic must exit normally, not time out")
      return result
    },
    close() {
      rmSync(dir, { recursive: true, force: true })
    },
  }
}

function resolved(f: ReturnType<typeof fixture>, name: string): ResolvedAgent {
  const result = f.run(["debug", "agent", name])
  assert.equal(result.status, 0, `${name}: ${result.error ?? ""}\n${result.stderr}`)
  return JSON.parse(result.stdout)
}

// Evaluate the ordered native resolver output using OpenCode's simple wildcards.
// Native edit enforcement is also exercised below in disposable workspaces.
function action(agent: ResolvedAgent, permission: string, resource = "*") {
  const matches = (pattern: string) =>
    new RegExp(
      `^${pattern
        .split("")
        .map((char) =>
          char === "*" ? ".*" : char === "?" ? "." : char.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
        )
        .join("")}$`
    ).test(resource)
  return agent.permission
    .filter(
      (rule) => (rule.permission === permission || rule.permission === "*") && matches(rule.pattern)
    )
    .at(-1)?.action
}

function assertPrimary(agent: ResolvedAgent) {
  assert.equal(agent.mode, "primary")
  for (const name of primaries)
    assert.equal(action(agent, "task", name), "deny", `${agent.name} must not task-invoke ${name}`)
  assert.equal(action(agent, "task", "explore"), "allow")
}

function assertLeaf(agent: ResolvedAgent) {
  assert.equal(agent.mode, "subagent")
  assert.equal(action(agent, "task"), "deny", `${agent.name} must remain a leaf`)
  if (agent.name === "explore")
    assert.equal(action(agent, "edit"), "deny", "explore must be read-only")
}

test("default and registration references match the selected native workflow", () => {
  assert.equal(config.default_agent, "direct")
  assert.equal(config.agent.plan.disable, true)
  assert.equal(config.agent.build.disable, true)
  assert.equal(config.agent.init, undefined, "/init is a command, not an agent")
  assert.deepEqual(
    Object.keys(config.agent)
      .filter((name) => !config.agent[name].disable)
      .sort(),
    [...primaries, ...leaves].sort()
  )
  for (const [name, agent] of Object.entries(config.agent) as [string, { prompt?: string }][]) {
    if (!agent.prompt) continue
    const match = agent.prompt.match(/^\{file:\.\/(prompts\/[a-z-]+\.md)\}$/)
    assert.ok(match, `${name} prompt must be a managed file reference`)
    assert.ok(existsSync(join(configRoot, match[1]!)), `${name} prompt exists`)
  }
  for (const file of readdirSync(join(configRoot, "commands")).filter((file) =>
    file.endsWith(".md")
  )) {
    const text = readFileSync(join(configRoot, "commands", file), "utf8")
    const agent = text.match(/^agent: ([a-z-]+)$/m)?.[1]
    assert.ok(
      agent && config.agent[agent] && !config.agent[agent].disable,
      `${file} references an active agent`
    )
  }
})

test("models, budgets and upstream plugin declarations are preserved", () => {
  assert.equal(config.model, "openai/gpt-6.1-sol")
  assert.equal(config.small_model, "openai/gpt-6-luna")
  assert.deepEqual(config.provider, { openai: { options: { reasoningEffort: "medium" } } })
  assert.deepEqual(config.plugin, [
    "cc-safety-net",
    "opencode-wakatime",
    "@mohak34/opencode-notifier@0.8.1",
    "context-mode",
  ])
  assert.equal(config.mcp?.["context-mode"], undefined)
  for (const [name, steps, temperature] of [
    ["planner", 120, 0.1],
    ["builder", 80, 0.1],
    ["direct", 120, 0.1],
    ["sudo", 160, 0.1],
    ["grind", 400, 0.1],
    ["audit", 160, 0.1],
    ["ideate", 160, 0.75],
    ["writer", 160, 0.75],
  ] as const) {
    assert.equal(config.agent[name].steps, steps, name)
    assert.equal(config.agent[name].temperature, temperature, name)
    assert.equal(config.agent[name].model, undefined, `${name} retains inherited model`)
  }
})

test("shared permissions are inherited with only role-specific overrides", () => {
  for (const name of ["direct", "builder"]) assert.equal(config.agent[name].permission, undefined)
  for (const name of ["general", "grind"])
    assert.deepEqual(config.agent[name].permission, { task: "deny" })
  assert.equal(config.permission.bash["nix *"], undefined)
  const f = fixture()
  try {
    const planner = resolved(f, "planner")
    assert.equal(action(planner, "bash"), "ask")
    assert.equal(action(planner, "bash", "nix develop"), "ask")
    assert.equal(action(planner, "bash", "git status --short"), "allow")
    assert.equal(action(planner, "bash", "gh pr view 123"), "allow")
    assert.equal(action(planner, "bash", "gh issue list"), "allow")
    assert.equal(action(planner, "bash", "gh pr create"), "ask")
    assert.equal(action(planner, "edit", "product.txt"), "deny")
    for (const name of ["direct", "builder", "general", "grind", "audit", "ideate", "writer"]) {
      const agent = resolved(f, name)
      for (const command of [
        "nix develop",
        "git status --short",
        "git diff --cached",
        "gh pr view 123",
        "gh pr diff 123",
        "gh pr checks 123",
        "gh pr list",
        "gh issue view 123",
        "gh issue list",
      ]) {
        assert.equal(action(agent, "bash", command), "allow", `${name}: ${command}`)
      }
      for (const command of [
        "git commit -m test",
        "git push",
        "gh pr create",
        "gh issue close 123",
        "gh api repos/owner/repo",
        "rm file",
        "sudo command",
      ]) {
        assert.equal(action(agent, "bash", command), "ask", `${name}: ${command}`)
      }
      assert.equal(action(agent, "external_directory", "/unfamiliar/path/file"), "ask", name)
      assert.equal(action(agent, "external_directory", join(f.workspace, "file")), "allow", name)
      assert.equal(
        action(agent, "external_directory", "/Users/shu/Documents/Obsidian Vault/note.md"),
        "allow",
        name
      )
    }
    for (const name of ["audit", "ideate", "writer"]) {
      assert.equal(action(resolved(f, name), "edit", "product.txt"), "deny", name)
      assert.equal(action(resolved(f, name), "edit", ".agents/receipt.md"), "allow", name)
    }
  } finally {
    f.close()
  }
})

test("handoff template has one task list and explicit gates, checks and closure", () => {
  const text = readFileSync(join(configRoot, "templates/plan.md"), "utf8")
  const headings = [...text.matchAll(/^## (.+)$/gm)].map((match) => match[1])
  assert.equal(headings.filter((heading) => heading === "Build handoff").length, 1)
  const tasks = [...text.matchAll(/^\s*- \[ \] (T\d+) /gm)].map((match) => match[1])
  assert.ok(tasks.length > 0)
  assert.equal(new Set(tasks).size, tasks.length, "task placeholders must not be duplicated")
  for (const field of [
    "Target files:",
    "Execution gates:",
    "redteam:",
    "sync-artifacts:",
    "Validation commands",
    "Stop conditions",
    "Escalation conditions",
    "Closure",
    "Builder prompt: Implement",
  ])
    assert.ok(text.includes(field), `handoff structure: ${field}`)
  // This is an artifact-shape check, not evidence that a model follows its prose.
})

test("actual native resolver enforces primary/leaf boundaries and reads candidate defaults", () => {
  const f = fixture()
  try {
    const result = f.run(["debug", "config"])
    assert.equal(result.status, 0, result.stderr)
    const agents = Object.fromEntries(
      [...primaries, ...leaves].map((name) => [name, resolved(f, name)])
    )
    if (process.env.OPENCODE_WORKFLOW_BASELINE === "1") {
      console.log(
        JSON.stringify({
          default: JSON.parse(result.stdout).default_agent,
          agents: Object.values(agents).map((agent) => ({
            name: agent.name,
            mode: agent.mode,
            steps: agent.steps,
            temperature: agent.temperature,
            model: agent.model ?? "inherited",
            taskPlanner: action(agent, "task", "planner"),
            taskGeneral: action(agent, "task", "general"),
            editAny: action(agent, "edit"),
          })),
        })
      )
    }
    assert.equal(JSON.parse(result.stdout).default_agent, "direct")
    for (const name of primaries) {
      const agent = agents[name]!
      assertPrimary(agent)
      assert.equal(agent.steps, config.agent[name].steps)
      assert.equal(agent.temperature, config.agent[name].temperature)
    }
    for (const name of leaves) assertLeaf(agents[name]!)
  } finally {
    f.close()
  }
})

test("native edit tools reject planner/explore product edits in disposable workspaces", () => {
  const f = fixture()
  try {
    const control = join(f.workspace, "builder-control.txt")
    const controlResult = f.run([
      "debug",
      "agent",
      "builder",
      "--tool",
      "apply_patch",
      "--params",
      JSON.stringify({
        patchText: `*** Begin Patch\n*** Add File: ${control}\n+harmless fixture\n*** End Patch`,
      }),
    ])
    assert.equal(controlResult.status, 0, `fixture edit control failed: ${controlResult.stderr}`)
    assert.equal(readFileSync(control, "utf8"), "harmless fixture\n")
    const receipt = join(f.workspace, ".agents/plans/receipt.md")
    const receiptResult = f.run([
      "debug",
      "agent",
      "planner",
      "--tool",
      "apply_patch",
      "--params",
      JSON.stringify({
        patchText: `*** Begin Patch\n*** Add File: ${receipt}\n+internal fixture\n*** End Patch`,
      }),
    ])
    assert.equal(
      receiptResult.status,
      0,
      `planner internal-state control failed: ${receiptResult.stderr}`
    )
    assert.equal(readFileSync(receipt, "utf8"), "internal fixture\n")
    for (const name of ["planner", "explore"]) {
      const file = join(f.workspace, `${name}-product.txt`)
      const params = JSON.stringify({
        patchText: `*** Begin Patch\n*** Add File: ${file}\n+harmless fixture\n*** End Patch`,
      })
      const result = f.run(["debug", "agent", name, "--tool", "apply_patch", "--params", params])
      assert.notEqual(result.status, 0, `${name} must reject product edits`)
      assert.match(`${result.stdout}\n${result.stderr}`, /denied|disabled|rule which prevents/i)
      assert.equal(existsSync(file), false, `${name} did not write its fixture`)
    }
  } finally {
    f.close()
  }
})

test("native resolution detects a removed primary deny, leaf deny and explore edit override", () => {
  const primary = structuredClone(config)
  delete primary.permission.task.planner
  const f = fixture(primary)
  try {
    assert.throws(() => assertPrimary(resolved(f, "planner")), /must not task-invoke planner/)
  } finally {
    f.close()
  }

  const leaf = structuredClone(config)
  delete leaf.agent.general.permission.task
  const g = fixture(leaf)
  try {
    assert.throws(() => assertLeaf(resolved(g, "general")), /must remain a leaf/)
  } finally {
    g.close()
  }

  const explorer = structuredClone(config)
  delete explorer.agent.explore.permission.edit
  const h = fixture(explorer)
  try {
    assert.throws(() => assertLeaf(resolved(h, "explore")), /must be read-only/)
  } finally {
    h.close()
  }

  const sudo = structuredClone(config)
  delete sudo.agent.sudo.permission.task
  const s = fixture(sudo)
  try {
    assert.throws(() => assertPrimary(resolved(s, "sudo")), /must not task-invoke/)
  } finally {
    s.close()
  }
})

test("native config loading rejects malformed JSON and missing prompt references", () => {
  const f = fixture()
  try {
    writeFileSync(f.configFile, "{broken")
    const syntax = f.run(["debug", "config"])
    assert.notEqual(syntax.status, 0)
    assert.match(`${syntax.stdout}\n${syntax.stderr}`, /json|parse|syntax/i)
    const invalid = structuredClone(config)
    invalid.agent.direct.prompt = "{file:./prompts/missing-workflow-fixture.md}"
    writeFileSync(f.configFile, JSON.stringify(invalid))
    const missing = f.run(["debug", "agent", "direct"])
    assert.notEqual(missing.status, 0)
    assert.match(
      `${missing.stdout}\n${missing.stderr}`,
      /missing-workflow-fixture|not found|ENOENT/i
    )
  } finally {
    f.close()
  }
})
