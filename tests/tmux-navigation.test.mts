import assert from "node:assert/strict"
import { mkdtempSync, mkdirSync, rmSync, symlinkSync } from "node:fs"
import { tmpdir } from "node:os"
import { execFileSync } from "node:child_process"
import { join } from "node:path"
import test from "node:test"
import {
  canonicalDirectory,
  collisionSessionName,
  discoverProjects,
  groupLabel,
  numberBindings,
  preferredSessionName,
  sessionsForProject,
} from "../modules/home-manager/core/tmux/navigation.mts"

test("grouping follows shared relative parent folders, not project names", () => {
  assert.equal(
    groupLabel("/home/user/Code/surge/atticus/atticus-editor", "/home/user"),
    "surge / atticus"
  )
  assert.equal(groupLabel("/home/user/Code/plain", "/home/user"), "Code")
  assert.equal(groupLabel("/home/user/nix-config", "/home/user"), "Local")
  assert.equal(groupLabel("relative", "/home/user"), "Other")
})

test("discovery preserves depth eligibility, deduplicates and skips hidden/symlink children", () => {
  const home = mkdtempSync(join(tmpdir(), "navigation-"))
  try {
    const root = join(home, "Code", "surge")
    const project = join(root, "atticus", "editor space")
    mkdirSync(project, { recursive: true })
    mkdirSync(join(root, ".hidden"))
    symlinkSync(project, join(root, "linked"))
    const items = discoverProjects({
      home,
      manualPaths: [project],
      roots: [{ path: root, minDepth: 1, maxDepth: 2 }],
    })
    assert.deepEqual(
      items.map((item) => item.label),
      ["atticus", "editor space"]
    )
    assert.equal(items.find((item) => item.label === "editor space")?.group, "surge / atticus")
    assert.equal(items.filter((item) => item.path === canonicalDirectory(project)).length, 1)
  } finally {
    rmSync(home, { recursive: true, force: true })
  }
})

test("same basename projects are distinct and collision names are deterministic", () => {
  const home = mkdtempSync(join(tmpdir(), "navigation-"))
  try {
    const first = join(home, "one", "api"),
      second = join(home, "two", "api")
    mkdirSync(first, { recursive: true })
    mkdirSync(second, { recursive: true })
    assert.equal(preferredSessionName(first), "api")
    assert.notEqual(collisionSessionName(first), collisionSessionName(second))
    assert.equal(collisionSessionName(second), collisionSessionName(second))
    const sessions = [{ id: "$9", name: "manually-named", path: first, group: "Local" }]
    assert.equal(sessionsForProject(sessions, first)[0].id, "$9")
    assert.deepEqual(sessionsForProject(sessions, second), [])
  } finally {
    rmSync(home, { recursive: true, force: true })
  }
})

test("numeric shortcuts use environment query data and never accept absent positions", () => {
  const bindings = numberBindings()
  const action = (index: number, query: string, count: string) =>
    execFileSync(
      process.env.TMUX_NAVIGATION_TEST_SHELL || "/bin/sh",
      ["-c", bindings[index].split(":transform:")[1]],
      { encoding: "utf8", env: { ...process.env, FZF_QUERY: query, FZF_MATCH_COUNT: count } }
    )
  assert.equal(action(0, "", "4"), "pos(1)+accept")
  assert.equal(action(8, "", "4"), "ignore")
  assert.equal(action(9, "", "10"), "pos(10)+accept")
  assert.equal(action(0, "atticus1", "4"), "put(1)")
  assert.equal(action(0, "$(exit 99);'", "4"), "put(1)")
})
