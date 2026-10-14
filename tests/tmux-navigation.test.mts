import assert from "node:assert/strict"
import {
  existsSync,
  mkdtempSync,
  mkdirSync,
  readFileSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs"
import { tmpdir } from "node:os"
import { execFileSync, spawnSync } from "node:child_process"
import { join } from "node:path"
import test from "node:test"
import { fileURLToPath } from "node:url"
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
  const home = canonicalDirectory(mkdtempSync(join(tmpdir(), "navigation-")))
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
      ["-c", bindings[index].split(":transform~")[1].slice(0, -1)],
      { encoding: "utf8", env: { ...process.env, FZF_QUERY: query, FZF_MATCH_COUNT: count } }
    )
  assert.equal(action(0, "", "4"), "pos(1)+accept")
  assert.equal(action(8, "", "4"), "ignore")
  assert.equal(action(9, "", "10"), "pos(10)+accept")
  assert.equal(action(0, "atticus1", "4"), "put(1)")
  assert.equal(action(0, "$(exit 99);'", "4"), "put(1)")
})

test("session CLI initially highlights the caller's third session without reordering rows", () => {
  const root = mkdtempSync(join(tmpdir(), "navigation-focus-"))
  try {
    const settings = join(root, "settings.json"),
      tmux = join(root, "tmux"),
      fzf = join(root, "fzf")
    writeFileSync(settings, JSON.stringify({ home: root, manualPaths: [], roots: [] }))
    writeFileSync(
      tmux,
      `#!${process.execPath}
      const args = process.argv.slice(2);
      if (args.includes('list-clients')) console.log('/dev/ttys999|4321|%9|$3');
      else if (args.includes('list-sessions')) console.log('$1\\n$2\\n$3');
      else if (args.includes('display-message')) {
        const id = args[args.indexOf('-t') + 1];
        console.log(args.at(-1) === '#{session_name}' ? {'$1:':'alpha','$2:':'beta','$3:':'gamma'}[id] : ${JSON.stringify(root)});
      } else process.exit(42);
    `,
      { mode: 0o700 }
    )
    writeFileSync(
      fzf,
      `#!${process.execPath}
      let input = '';
      process.stdin.on('data', data => input += data);
      process.stdin.on('end', () => {
        console.error(JSON.stringify({args: process.argv.slice(2), input}));
        process.exit(130);
      });
    `,
      { mode: 0o700 }
    )
    const result = spawnSync(
      process.execPath,
      [
        fileURLToPath(new URL("../modules/home-manager/core/tmux/navigation.mts", import.meta.url)),
        "sessions",
        "--client",
        "/dev/ttys999",
        "--socket",
        join(root, "socket"),
      ],
      {
        encoding: "utf8",
        timeout: 5000,
        env: {
          ...process.env,
          TMUX_NAVIGATION_SETTINGS: settings,
          TMUX_NAVIGATION_TMUX: tmux,
          TMUX_NAVIGATION_FZF: fzf,
        },
      }
    )
    assert.equal(result.status, 0, result.stderr)
    const picker = JSON.parse(result.stderr)
    assert.ok(picker.args.includes("--sync"))
    assert.ok(picker.args.some((arg: string) => arg.includes("start:pos(3)")))
    assert.deepEqual(
      picker.input
        .trim()
        .split("\n")
        .map((row: string) => row.split("\t")[0]),
      ["$1", "$2", "$3"]
    )
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

test("real fzf keeps initial focus and numeric shortcuts after the results settle", async () => {
  const root = mkdtempSync(join(tmpdir(), "nf-"))
  const socket = join(root, "tmux"),
    settings = join(root, "settings.json")
  const selection = join(root, "selection")
  const mockTmux = join(root, "mock-tmux"),
    picker = join(root, "picker")
  const env = {
    ...process.env,
    TMUX_NAVIGATION_SETTINGS: settings,
    TMUX_NAVIGATION_TMUX: mockTmux,
    TMUX_NAVIGATION_FZF: picker,
  }
  const tmux = (...args: string[]) =>
    execFileSync("tmux", ["-S", socket, ...args], {
      env,
      encoding: "utf8",
      timeout: 3000,
      stdio: ["ignore", "pipe", "pipe"],
    })
  try {
    writeFileSync(settings, JSON.stringify({ home: root, manualPaths: [], roots: [] }))
    writeFileSync(
      mockTmux,
      `#!${process.execPath}
      const {writeFileSync} = await import('node:fs');
      const args = process.argv.slice(2);
      if (args.includes('list-clients')) console.log('/dev/ttys999|4321|%9|$3');
      else if (args.includes('list-sessions')) console.log('$1\\n$2\\n$3');
      else if (args.includes('display-message')) console.log(args.at(-1) === '#{session_name}' ? {'$1:':'alpha','$2:':'beta','$3:':'gamma'}[args[args.indexOf('-t') + 1]] : ${JSON.stringify(root)});
      else if (args.includes('switch-client')) writeFileSync(${JSON.stringify(selection)}, args[args.indexOf('-t') + 1]);
      else process.exit(42);
    `,
      { mode: 0o700 }
    )
    writeFileSync(
      picker,
      `#!${process.execPath}
      const {spawn} = await import('node:child_process');
      const child = spawn(${JSON.stringify(process.env.TMUX_NAVIGATION_TEST_FZF || "fzf")}, [...process.argv.slice(2), '--pointer=>', '--color=bw'], {stdio:'inherit'});
      child.on('error', () => process.exit(2));
      child.on('exit', code => process.exit(code ?? 2));
    `,
      { mode: 0o700 }
    )
    tmux(
      "-f",
      "/dev/null",
      "new-session",
      "-d",
      "-s",
      "focus",
      "-x",
      "100",
      "-y",
      "30",
      process.execPath,
      fileURLToPath(new URL("../modules/home-manager/core/tmux/navigation.mts", import.meta.url)),
      "sessions",
      "--client",
      "/dev/ttys999",
      "--socket",
      socket
    )
    let screen = ""
    for (let tries = 0; tries < 40; tries++) {
      await new Promise((resolve) => setTimeout(resolve, 50))
      screen = tmux("capture-pane", "-p", "-t", "focus:0.0")
      if (screen.includes("gamma")) break
    }
    await new Promise((resolve) => setTimeout(resolve, 300))
    screen = tmux("capture-pane", "-p", "-t", "focus:0.0")
    assert.match(screen, /^>\s*3\s+Local.*gamma/m, screen)
    tmux("send-keys", "-t", "focus:0.0", "9", "0")
    await new Promise((resolve) => setTimeout(resolve, 150))
    assert.equal(existsSync(selection), false, "Absent numeric positions must not select a session")
    assert.match(tmux("capture-pane", "-p", "-t", "focus:0.0"), /^>\s*3\s+Local.*gamma/m)
    tmux("send-keys", "-t", "focus:0.0", "b", "2")
    await new Promise((resolve) => setTimeout(resolve, 300))
    assert.equal(
      existsSync(selection),
      false,
      "Digits in a nonempty query must not select a session"
    )
    assert.match(tmux("capture-pane", "-p", "-t", "focus:0.0"), /^> b2/m)
    tmux("send-keys", "-t", "focus:0.0", "C-u")
    await new Promise((resolve) => setTimeout(resolve, 150))
    tmux("send-keys", "-t", "focus:0.0", "2")
    for (let tries = 0; !existsSync(selection) && tries < 40; tries++) {
      await new Promise((resolve) => setTimeout(resolve, 50))
    }
    assert.ok(existsSync(selection), "Numeric key 2 must select, not merely enter a search query")
    assert.equal(readFileSync(selection, "utf8"), "$2")
  } finally {
    try {
      tmux("kill-server")
    } catch {}
    rmSync(root, { recursive: true, force: true })
  }
})
