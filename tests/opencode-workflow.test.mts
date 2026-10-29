import assert from "node:assert/strict"
import { spawnSync } from "node:child_process"
import {
  closeSync,
  cpSync,
  existsSync,
  mkdirSync,
  openSync,
  mkdtempSync,
  readFileSync,
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
const binary = process.env.OPENCODE_TEST_BINARY ?? "opencode"
const leaves = ["general", "explore", "reviewer"]

interface Rule {
  permission: string
  pattern: string
  action: string
}
interface Agent {
  name: string
  mode: string
  permission: Rule[]
  model?: unknown
}

function fixture(candidate = config) {
  const dir = realpathSync(mkdtempSync(join(tmpdir(), "opencode-workflow-")))
  const home = join(dir, "home")
  const workspace = join(home, "Code/workspace")
  const installed = join(home, ".config/opencode")
  mkdirSync(workspace, { recursive: true })
  mkdirSync(installed, { recursive: true })
  for (const entry of ["prompts", "instructions", "skills", "commands"])
    cpSync(join(configRoot, entry), join(installed, entry), { recursive: true })
  writeFileSync(join(installed, "opencode.json"), JSON.stringify({ ...candidate, plugin: [] }))
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
      const stdoutPath = join(dir, "stdout")
      const stderrPath = join(dir, "stderr")
      const stdout = openSync(stdoutPath, "w")
      const stderr = openSync(stderrPath, "w")
      try {
        const result = spawnSync(binary, ["--pure", ...args], {
          cwd: workspace,
          env,
          timeout: 20000,
          stdio: ["ignore", stdout, stderr],
        })
        assert.ifError(result.error)
        assert.notEqual(result.status, null, "native diagnostic must exit normally")
        return {
          ...result,
          stdout: readFileSync(stdoutPath, "utf8"),
          stderr: readFileSync(stderrPath, "utf8"),
        }
      } finally {
        closeSync(stdout)
        closeSync(stderr)
      }
    },
    close() {
      rmSync(dir, { recursive: true, force: true })
    },
  }
}

function resolved(f: ReturnType<typeof fixture>, name: string): Agent {
  const result = f.run(["debug", "agent", name])
  assert.equal(result.status, 0, `${name}: ${result.stderr}`)
  return JSON.parse(result.stdout)
}

function action(agent: Agent, permission: string, resource = "*") {
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

function assertCoordinator(agent: Agent) {
  assert.equal(agent.mode, "primary")
  assert.equal(action(agent, "task", "jiyu"), "deny")
  for (const leaf of leaves) assert.equal(action(agent, "task", leaf), "allow", leaf)
}

function assertLeaf(agent: Agent) {
  assert.equal(agent.mode, "subagent")
  assert.equal(action(agent, "task", "general"), "deny", "workers cannot delegate")
  if (agent.name !== "general") assert.equal(action(agent, "edit"), "deny", "review is read-only")
}

test("OpenCode resolves the default coordinator and bounded inherited workers", () => {
  const f = fixture()
  try {
    const result = f.run(["debug", "config"])
    assert.equal(result.status, 0, result.stderr)
    const loaded = JSON.parse(result.stdout)
    assert.equal(loaded.default_agent, "jiyu")
    assertCoordinator(resolved(f, loaded.default_agent))
    for (const name of leaves) {
      const agent = resolved(f, name)
      assertLeaf(agent)
      assert.equal(agent.model, undefined, "role models inherit rather than using Cursor slugs")
    }
  } finally {
    f.close()
  }
})

test("ordinary checks run while destructive and operational commands retain approval", () => {
  const f = fixture()
  try {
    const agent = resolved(f, "jiyu")
    for (const command of [
      "rg retry src",
      "git diff --cached",
      "just check",
      "just build-dry",
      "pnpm test",
    ])
      assert.equal(action(agent, "bash", command), "allow", command)
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
      assert.equal(action(agent, "bash", command), "ask", command)
    assert.equal(action(agent, "external_directory", "/unfamiliar/path/file"), "ask")
    assert.equal(action(agent, "external_directory", join(f.workspace, "file")), "allow")
    for (const prefix of ["/var/folders", "/private/var/folders"]) {
      for (const userDir of ["24/1sdtr2d96q75lv2m5mpy4f_m0000gn", "ab/a-different-temp-id"]) {
        const temp = `${prefix}/${userDir}/T`
        for (const path of [`${temp}/opencode/*`, `${temp}/opencode/session/output.txt`])
          assert.equal(action(agent, "external_directory", path), "allow", path)
        for (const path of [`${temp}/other/*`, `${temp}/opencode-other/*`])
          assert.equal(action(agent, "external_directory", path), "ask", path)
      }
    }
  } finally {
    f.close()
  }
})

test("native discovery loads requested skills and their command entrypoints", () => {
  const f = fixture()
  try {
    const result = f.run(["debug", "skill"])
    assert.equal(result.status, 0, result.stderr)
    const skills: { name: string; location: string }[] = JSON.parse(result.stdout)
    const names = new Set(skills.map((skill) => skill.name))
    const requested = [
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
    ]
    const loadedResult = f.run(["debug", "config"])
    assert.equal(loadedResult.status, 0, loadedResult.stderr)
    const loaded = JSON.parse(loadedResult.stdout)
    for (const name of requested) {
      assert.ok(names.has(name), `${name} is discoverable`)
      assert.equal(loaded.command[name].agent, "jiyu", `/${name} uses the primary session`)
    }
    for (const name of ["engineering-quality", "brainstorming", "handoff", "humanizer"])
      assert.equal(names.has(name), false, `${name} is retired`)
  } finally {
    f.close()
  }
})

test("native tools allow implementation and reject reviewer and explorer writes", () => {
  const f = fixture()
  try {
    for (const name of ["jiyu", "general", "reviewer", "explore"]) {
      const file = join(f.workspace, `${name}-product.txt`)
      const result = f.run([
        "debug",
        "agent",
        name,
        "--tool",
        "apply_patch",
        "--params",
        JSON.stringify({
          patchText: `*** Begin Patch\n*** Add File: ${file}\n+fixture\n*** End Patch`,
        }),
      ])
      if (name === "jiyu" || name === "general") {
        assert.equal(result.status, 0, result.stderr)
        assert.equal(readFileSync(file, "utf8"), "fixture\n")
      } else {
        assert.notEqual(result.status, 0)
        assert.match(`${result.stdout}\n${result.stderr}`, /denied|disabled|rule which prevents/i)
        assert.equal(existsSync(file), false)
      }
    }
    const receipt = join(f.workspace, ".agents/reviewer-note.md")
    const result = f.run([
      "debug",
      "agent",
      "reviewer",
      "--tool",
      "apply_patch",
      "--params",
      JSON.stringify({
        patchText: `*** Begin Patch\n*** Add File: ${receipt}\n+fixture\n*** End Patch`,
      }),
    ])
    assert.notEqual(result.status, 0, "shared state has no reviewer write exception")
    assert.equal(existsSync(receipt), false)
  } finally {
    f.close()
  }
})

test("native resolution exposes permission regressions in candidate configurations", () => {
  const primary = structuredClone(config)
  primary.permission.task["*"] = "allow"
  const f = fixture(primary)
  try {
    assert.throws(() => assertCoordinator(resolved(f, "jiyu")))
  } finally {
    f.close()
  }

  const reviewer = structuredClone(config)
  reviewer.agent.reviewer.permission.edit = "allow"
  const g = fixture(reviewer)
  try {
    assert.throws(() => assertLeaf(resolved(g, "reviewer")))
  } finally {
    g.close()
  }

  const worker = structuredClone(config)
  worker.agent.general.permission.task = "allow"
  const h = fixture(worker)
  try {
    assert.throws(() => assertLeaf(resolved(h, "general")))
  } finally {
    h.close()
  }
})

test("native loading rejects malformed configuration and missing prompt files", () => {
  const f = fixture()
  try {
    writeFileSync(f.configFile, "{broken")
    const syntax = f.run(["debug", "config"])
    assert.notEqual(syntax.status, 0)
    assert.match(`${syntax.stdout}\n${syntax.stderr}`, /json|parse|syntax/i)
    const invalid = structuredClone(config)
    invalid.agent.jiyu.prompt = "{file:./prompts/missing-fixture.md}"
    writeFileSync(f.configFile, JSON.stringify({ ...invalid, plugin: [] }))
    const missing = f.run(["debug", "agent", "jiyu"])
    assert.notEqual(missing.status, 0)
    assert.match(`${missing.stdout}\n${missing.stderr}`, /missing-fixture|not found|ENOENT/i)
  } finally {
    f.close()
  }
})
