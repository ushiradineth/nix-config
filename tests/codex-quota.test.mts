import assert from "node:assert/strict"
import test from "node:test"
import {
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  statSync,
  symlinkSync,
  writeFileSync,
} from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { execFileSync, spawn } from "node:child_process"
import { fileURLToPath } from "node:url"
import {
  createQuotaCache,
  decodeQuota,
  formatQuota,
  readQuota,
} from "../modules/home-manager/core/tmux/codex-quota.mts"

const weekly = { usedPercent: 19, windowDurationMins: 10080, resetsAt: 2000000000 }

test("weekly quota in primary is displayed as percentage remaining", () => {
  assert.equal(
    formatQuota(decodeQuota({ rateLimits: { primary: weekly, secondary: null } })),
    "81% Codex Quota Remaining (weekly)"
  )
})

const short = { usedPercent: 32, windowDurationMins: 300, resetsAt: 2000000100 }

test("either field can carry either window, including secondary-only weekly quota", () => {
  for (const [primary, secondary] of [
    [weekly, short],
    [short, weekly],
  ]) {
    assert.equal(
      formatQuota(decodeQuota({ rateLimits: { primary, secondary } })),
      "68% Codex Quota Remaining (5h) | 81% Codex Quota Remaining (weekly)"
    )
  }
  assert.equal(
    formatQuota(decodeQuota({ rateLimits: { primary: null, secondary: weekly } })),
    "81% Codex Quota Remaining (weekly)"
  )
  assert.equal(formatQuota(decodeQuota({ rateLimits: {} })), "CX:n/a")
})

test("only the codex bucket is selected, with legacy fallback only without a map", () => {
  const legacy = { primary: short }
  assert.equal(
    formatQuota(
      decodeQuota({ rateLimits: legacy, rateLimitsByLimitId: { codex: { primary: weekly } } })
    ),
    "81% Codex Quota Remaining (weekly)"
  )
  assert.equal(
    formatQuota(decodeQuota({ rateLimits: legacy, rateLimitsByLimitId: { other: legacy } })),
    "CX:n/a"
  )
  assert.equal(
    formatQuota(decodeQuota({ rateLimits: { limitId: "other", primary: short } })),
    "CX:n/a"
  )
  assert.equal(
    formatQuota(decodeQuota({ rateLimits: legacy, rateLimitsByLimitId: null })),
    "68% Codex Quota Remaining (5h)"
  )
})

test("valid unknown durations and percentage boundaries keep literal semantics", () => {
  assert.equal(
    formatQuota(
      decodeQuota({
        rateLimits: {
          primary: { ...short, usedPercent: 0 },
          secondary: { ...weekly, usedPercent: 100 },
        },
      })
    ),
    "100% Codex Quota Remaining (5h) | 0% Codex Quota Remaining (weekly)"
  )
  assert.equal(
    formatQuota(
      decodeQuota({
        rateLimits: { primary: { ...short, usedPercent: 19.6, windowDurationMins: 90 } },
      })
    ),
    "80% Codex Quota Remaining (90m)"
  )
  assert.equal(
    formatQuota(decodeQuota({ rateLimits: { primary: { ...weekly, usedPercent: 28 } } })),
    "72% Codex Quota Remaining (weekly)"
  )
  assert.equal(
    formatQuota(decodeQuota({ rateLimits: { primary: { ...weekly, usedPercent: 19.5 } } })),
    "81% Codex Quota Remaining (weekly)"
  )
})

test("malformed values cannot become tmux format or false quota numbers", () => {
  for (const field of ["usedPercent", "windowDurationMins", "resetsAt"]) {
    for (const value of ["#[fg=red]", NaN, Infinity, -1]) {
      assert.throws(
        () => decodeQuota({ rateLimits: { primary: { ...weekly, [field]: value } } }),
        /Invalid quota/
      )
    }
  }
  assert.throws(() => decodeQuota({ rateLimits: { primary: { ...weekly, usedPercent: 101 } } }))
  assert.throws(() => decodeQuota({ rateLimits: { primary: { ...weekly, resetsAt: 1.5 } } }))
})

function server(mode = "ok") {
  return `
    import {createInterface} from 'node:readline';
    const mode = ${JSON.stringify(mode)};
    if (mode === 'hang') setInterval(() => {}, 1000);
    const expected = ['initialize', 'initialized', 'account/rateLimits/read'];
    let index = 0;
    const send = x => process.stdout.write(JSON.stringify(x) + '\\n');
    createInterface({input: process.stdin}).on('line', line => {
      const m = JSON.parse(line);
      if (m.method !== expected[index++]) process.exit(42);
      if (m.method === 'initialize') {
        if (mode === 'hang') { process.on('SIGTERM', () => {}); return; }
        if (mode === 'oversize') { process.stdout.write('x'.repeat(70000)); return; }
        if (mode === 'invalid') { process.stdout.write('not-json\\n'); return; }
        send({id: 999, result: {}});
        send({method: 'unrelated', params: {}});
        send({id: m.id, result: {}});
      }
      if (m.method === 'account/rateLimits/read') {
        if (mode === 'auth') send({id:m.id, error:{code:401,message:'not authenticated secret-never-output'}});
        else if (mode === 'error') send({id:m.id, error:{code:-32000,message:'private-failure'}});
        else send({id:m.id,result:{rateLimits:{primary:${JSON.stringify(weekly)},secondary:null},private:'never-persist'}});
      }
    });
  `
}

test("app-server handshake reads quota without invoking a thread or model", async () => {
  const result = await readQuota({
    command: process.execPath,
    prefixArgs: ["--input-type=module", "-e", server()],
  })
  assert.deepEqual(result, { kind: "ok", windows: [weekly] })
})

test("protocol errors, oversized output and authentication failures are sanitized", async () => {
  for (const mode of ["auth", "error", "invalid", "oversize"]) {
    assert.deepEqual(
      await readQuota({
        command: process.execPath,
        prefixArgs: ["--input-type=module", "-e", server(mode)],
      }),
      { kind: mode === "auth" ? "auth" : "error" }
    )
  }
  assert.deepEqual(await readQuota({ command: "/nonexistent/codex-quota-test" }), {
    kind: "unavailable",
  })
})

test("timeout kills even a server that ignores SIGTERM", async () => {
  const start = Date.now()
  assert.deepEqual(
    await readQuota({
      command: process.execPath,
      prefixArgs: ["--input-type=module", "-e", server("hang")],
      timeoutMs: 150,
    }),
    { kind: "error" }
  )
  assert.ok(Date.now() - start < 3000)
})

test("cold status launches once and warm status reads private sanitized cache", async () => {
  const root = mkdtempSync(join(tmpdir(), "cq-"))
  const tokens: string[] = []
  const cache = createQuotaCache({
    directory: root,
    codexHome: join(root, "home"),
    launch: (token) => tokens.push(token),
    readOptions: { command: process.execPath, prefixArgs: ["--input-type=module", "-e", server()] },
  })
  try {
    assert.equal(cache.status(), "CX:…")
    assert.equal(cache.status(), "CX:…")
    assert.equal(tokens.length, 1)
    await cache.refresh(tokens[0])
    assert.equal(cache.status(), "81% Codex Quota Remaining (weekly)")
    assert.equal(tokens.length, 1)
    const raw = readFileSync(join(cache.directory, "state.json"), "utf8")
    assert.doesNotMatch(raw, /never-persist|private|account|token/i)
    assert.equal(statSync(cache.directory).mode & 0o777, 0o700)
    assert.equal(statSync(join(cache.directory, "state.json")).mode & 0o777, 0o600)
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

function cacheFixture() {
  const root = mkdtempSync(join(tmpdir(), "cq-"))
  const tokens: string[] = []
  let time = Date.now()
  const readOptions = {
    command: process.execPath,
    prefixArgs: ["--input-type=module", "-e", server()],
  }
  const cache = createQuotaCache({
    directory: root,
    codexHome: join(root, "home"),
    now: () => time,
    launch: (token) => tokens.push(token),
    readOptions,
  })
  return {
    root,
    tokens,
    cache,
    readOptions,
    advance: (ms: number) => {
      time += ms
    },
    time: () => time,
    close: () => rmSync(root, { recursive: true, force: true }),
  }
}

test("stale cache is qualified, failures retry at most once per minute and expire", async () => {
  const f = cacheFixture()
  try {
    f.cache.status()
    await f.cache.refresh(f.tokens[0])
    f.advance(300000)
    assert.equal(f.cache.status(), "81% Codex Quota Remaining (weekly) stale")
    assert.equal(f.tokens.length, 2)
    f.readOptions.prefixArgs = ["--input-type=module", "-e", server("error")]
    await f.cache.refresh(f.tokens[1])
    f.advance(59000)
    assert.equal(f.cache.status(), "81% Codex Quota Remaining (weekly) stale")
    assert.equal(f.tokens.length, 2)
    f.advance(1000)
    f.cache.status()
    assert.equal(f.tokens.length, 3)
    await f.cache.refresh(f.tokens[2])
    f.advance(600001)
    assert.equal(f.cache.status(), "CX:n/a")
  } finally {
    f.close()
  }
})

test("authentication loss clears percentages and missing CLI is negatively cached", async () => {
  const f = cacheFixture()
  try {
    f.cache.status()
    await f.cache.refresh(f.tokens[0])
    f.advance(300000)
    f.cache.status()
    f.readOptions.prefixArgs = ["--input-type=module", "-e", server("auth")]
    await f.cache.refresh(f.tokens[1])
    assert.equal(f.cache.status(), "CX:n/a")
    const state = readFileSync(join(f.cache.directory, "state.json"), "utf8")
    assert.doesNotMatch(state, /secret-never-output/)
    assert.deepEqual(JSON.parse(state).windows, [])
    f.advance(60000)
    f.cache.status()
    f.readOptions.command = "/nonexistent/codex-quota-test"
    await f.cache.refresh(f.tokens[2])
    assert.equal(f.cache.status(), "CX:n/a")
    assert.equal(f.tokens.length, 3)
  } finally {
    f.close()
  }
})

test("reset invalidates freshness without repeated successful polls of an expired window", async () => {
  const f = cacheFixture()
  try {
    const reset = Math.floor(f.time() / 1000) + 10
    f.readOptions.prefixArgs = [
      "--input-type=module",
      "-e",
      server().replace(JSON.stringify(weekly), JSON.stringify({ ...weekly, resetsAt: reset })),
    ]
    f.cache.status()
    await f.cache.refresh(f.tokens[0])
    f.advance(11000)
    assert.equal(f.cache.status(), "81% Codex Quota Remaining (weekly) stale")
    await f.cache.refresh(f.tokens[1])
    assert.equal(f.cache.status(), "81% Codex Quota Remaining (weekly) stale")
    assert.equal(f.tokens.length, 2)
  } finally {
    f.close()
  }
})

test("abandoned leases recover without allowing an old worker to publish", async () => {
  const f = cacheFixture()
  try {
    f.cache.status()
    f.advance(31000)
    f.cache.status()
    assert.equal(f.tokens.length, 2)
    await f.cache.refresh(f.tokens[0])
    assert.equal(existsSync(join(f.cache.directory, "state.json")), false)
    await f.cache.refresh(f.tokens[1])
    assert.equal(f.cache.status(), "81% Codex Quota Remaining (weekly)")
  } finally {
    f.close()
  }
})

test("corrupt cache and unsafe directory cannot expose arbitrary status text", () => {
  const f = cacheFixture()
  try {
    f.cache.status()
    writeFileSync(join(f.cache.directory, "state.json"), '{"windows":"#[fg=red]"}', { mode: 0o600 })
    assert.equal(f.cache.status(), "CX:…")
    const link = join(f.root, "link")
    symlinkSync(f.cache.directory, link)
    const unsafe = createQuotaCache({
      directory: link,
      launch: () => {
        throw new Error("should not launch")
      },
    })
    assert.equal(unsafe.status(), "CX:n/a")
  } finally {
    f.close()
  }
})

test("different Codex homes never reuse a snapshot and worker launch failure is bounded", () => {
  const f = cacheFixture()
  try {
    const other = createQuotaCache({
      directory: f.root,
      codexHome: join(f.root, "other"),
      launch: () => {
        throw new Error("private-spawn-error")
      },
    })
    assert.notEqual(other.directory, f.cache.directory)
    assert.equal(other.status(), "CX:n/a")
    assert.equal(other.status(), "CX:n/a")
    assert.equal(existsSync(join(other.directory, "lock.json")), false)
    assert.doesNotMatch(
      readFileSync(join(other.directory, "state.json"), "utf8"),
      /private-spawn-error/
    )
  } finally {
    f.close()
  }
})

const helper = fileURLToPath(
  new URL("../modules/home-manager/core/tmux/codex-quota.mts", import.meta.url)
)

test("concurrent CLI status calls detach one bounded refresh and reuse its snapshot", async () => {
  const root = mkdtempSync(join(tmpdir(), "cq-"))
  const fake = join(root, "codex.mjs"),
    count = join(root, "reads")
  writeFileSync(
    fake,
    `#!${process.execPath}\nimport {appendFileSync} from 'node:fs';\n${server().replace("if (m.method === 'initialize') {", "if (m.method === 'initialize') { appendFileSync(process.env.CQ_COUNT, '1\\n');")}`,
    { mode: 0o700 }
  )
  const env = {
    ...process.env,
    HOME: root,
    CODEX_HOME: join(root, "home"),
    CODEX_QUOTA_CACHE_DIR: join(root, "cache"),
    CODEX_QUOTA_CODEX: fake,
    CQ_COUNT: count,
  }
  const status = () =>
    execFileSync(process.execPath, [helper, "status"], {
      env,
      encoding: "utf8",
      timeout: 2000,
    }).trim()
  try {
    await Promise.all(
      Array.from(
        { length: 8 },
        () =>
          new Promise<void>((resolve, reject) => {
            const child = spawn(process.execPath, [helper, "status"], {
              env,
              stdio: ["ignore", "pipe", "pipe"],
            })
            let output = "",
              error = ""
            child.stdout.on("data", (data) => {
              output += data
            })
            child.stderr.on("data", (data) => {
              error += data
            })
            child.on("error", reject)
            child.on("close", (code) => {
              try {
                assert.equal(code, 0)
                assert.equal(error, "")
                assert.match(output.trim(), /^(CX:…|81% Codex Quota Remaining \(weekly\))$/u)
                resolve()
              } catch (error) {
                reject(error)
              }
            })
          })
      )
    )
    const deadline = Date.now() + 10000
    let output = status()
    while (output !== "81% Codex Quota Remaining (weekly)" && Date.now() < deadline) {
      await new Promise((resolve) => setTimeout(resolve, 50))
      output = status()
    }
    assert.equal(output, "81% Codex Quota Remaining (weekly)")
    assert.equal(readFileSync(count, "utf8"), "1\n")
    assert.equal(status(), "81% Codex Quota Remaining (weekly)")
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

test("isolated tmux toggles remaining quota without hiding OC and preserves choice on reload", async () => {
  const root = mkdtempSync(join(tmpdir(), "cq-")),
    socket = join(root, "tmux")
  const fake = join(root, "codex.mjs"),
    config = join(root, "tmux.conf")
  writeFileSync(fake, `#!${process.execPath}\n${server()}`, { mode: 0o700 })
  const env = {
    ...process.env,
    HOME: root,
    TMUX: "",
    TMUX_PANE: "",
    CODEX_HOME: join(root, "home"),
    CODEX_QUOTA_CACHE_DIR: join(root, "cache"),
    CODEX_QUOTA_CODEX: fake,
  }
  const packagePath = process.env.CODEX_QUOTA_TEST_HELPER
  const quotaCommand = packagePath
    ? `${packagePath} status`
    : `${process.execPath} ${helper} status`
  const source =
    process.env.CODEX_QUOTA_TEST_CONFIG ||
    fileURLToPath(new URL("../modules/home-manager/core/tmux/.tmux.conf", import.meta.url))
  const text = readFileSync(source, "utf8")
  writeFileSync(config, packagePath ? text : text.replace("codex-quota status", quotaCommand))
  const tmux = (...args: string[]) =>
    execFileSync("tmux", ["-S", socket, ...args], { env, encoding: "utf8", timeout: 3000 }).trim()
  let client: ReturnType<typeof spawn> | undefined
  try {
    tmux("-f", "/dev/null", "new-session", "-d", "-s", "quota", "sleep 60")
    const paneNumbers = tmux("list-keys", "-T", "prefix", "q")
    client = spawn("tmux", ["-S", socket, "-C", "attach-session", "-t", "quota"], {
      env,
      stdio: ["pipe", "pipe", "pipe"],
    })
    let buffer = ""
    const replies: ((value: string) => void)[] = []
    client.stdout?.on("data", (data) => {
      buffer += data.toString()
      while (buffer.includes("\n")) {
        const newline = buffer.indexOf("\n"),
          line = buffer.slice(0, newline)
        buffer = buffer.slice(newline + 1)
        if (line.startsWith("CQ_RESULT:")) replies.shift()?.(line.slice("CQ_RESULT:".length))
      }
    })
    client.stderr?.resume()
    for (let tries = 0; !tmux("list-clients") && tries < 50; tries++)
      await new Promise((resolve) => setTimeout(resolve, 20))
    tmux("source-file", config)
    assert.equal(tmux("show-option", "-gqv", "@codex_quota_visible"), "1")
    assert.equal(tmux("list-keys", "-T", "prefix", "q"), paneNumbers)
    if (packagePath)
      assert.ok(tmux("show-option", "-gv", "status-right").includes(`${packagePath} status`))
    assert.ok(tmux("list-clients"))
    // Format jobs belong to the command client, not display-message's -c target.
    const output = () =>
      new Promise<string>((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error("Control client did not reply")), 3000)
        replies.push((value) => {
          clearTimeout(timer)
          resolve(value)
        })
        client?.stdin?.write("display-message -p 'CQ_RESULT:#{E:status-right}'\n")
      })
    const toggle = () => {
      const binding = tmux("list-keys", "-T", "prefix", "Q")
      const command = binding.replace(/^bind-key\s+-T\s+prefix\s+Q\s+/, "")
      assert.match(command, /^if-shell /)
      client?.stdin?.write(command + "\n")
    }
    toggle()
    assert.equal(await output(), "")
    tmux("source-file", config)
    assert.equal(tmux("show-option", "-gv", "@codex_quota_visible"), "0")
    assert.equal(await output(), "")
    await new Promise((resolve) => setTimeout(resolve, 200))
    assert.equal(existsSync(join(root, "cache")), false)
    toggle()
    const deadline = Date.now() + 10000
    let value = await output()
    while (!value.includes("81% Codex Quota Remaining (weekly)") && Date.now() < deadline) {
      await new Promise((resolve) => setTimeout(resolve, 100))
      value = await output()
    }
    assert.equal(value, "81% Codex Quota Remaining (weekly)")
    tmux("set-option", "-g", "@opencode_terminal_attention", "2")
    const attention = "#[fg=#FF95B5,bold]OC:2#[default]"
    assert.equal(await output(), `81% Codex Quota Remaining (weekly) ${attention}`)
    toggle()
    assert.equal(await output(), attention)
    tmux("rename-window", "kept-name")
    tmux("source-file", config)
    assert.equal(await output(), attention)
    assert.equal(tmux("show-option", "-gv", "@codex_quota_visible"), "0")
    toggle()
    assert.equal(await output(), `81% Codex Quota Remaining (weekly) ${attention}`)
    tmux("source-file", config)
    assert.equal(tmux("show-option", "-gv", "@codex_quota_visible"), "1")
    assert.equal(tmux("display-message", "-p", "#{window_name}"), "kept-name")
    assert.equal(tmux("show-option", "-gv", "pane-border-status"), "off")
  } finally {
    client?.stdin?.end("detach-client\n")
    client?.kill()
    try {
      tmux("kill-server")
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  }
})
