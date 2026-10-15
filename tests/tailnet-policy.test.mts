import { test } from "node:test"
import assert from "node:assert/strict"
import {
  mkdtempSync,
  mkdirSync,
  writeFileSync,
  readFileSync,
  chmodSync,
  rmSync,
  statSync,
  symlinkSync,
  readdirSync,
} from "node:fs"
import { tmpdir } from "node:os"
import { join, resolve } from "node:path"
import { spawn, spawnSync } from "node:child_process"

const script = resolve("scripts/tailnet-policy.sh")
const baseline = '// HuJSON baseline\n{"acls": [],}\n'
const candidate = '// reviewed candidate\n{"acls": [], "tests": [],}\n'

function preparedPolicy() {
  return JSON.parse(
    readFileSync(resolve("network/tailscale/policy.hujson"), "utf8").replace(/^\s*\/\/.*$/gm, "")
  )
}

test("prepared policy preserves network grants, tags, empty DNS group and offline admin capabilities", () => {
  const policy = preparedPolicy()
  assert.deepEqual(policy.acls, [
    { action: "accept", src: ["*"], dst: ["autogroup:self:*"] },
    {
      action: "accept",
      src: ["tag:admin", "tag:personal", "tag:shupi", "tag:shulab"],
      dst: ["autogroup:internet:*"],
    },
    {
      action: "accept",
      src: ["tag:admin", "tag:personal"],
      dst: ["tag:shupi:53", "tag:shupi:80", "tag:shupi:443", "tag:shulab:443"],
    },
    {
      action: "accept",
      src: ["tag:admin"],
      dst: ["tag:shupi:22", "tag:shulab:22", "tag:shuwin:22"],
    },
    { action: "accept", src: ["tag:admin", "tag:personal"], dst: ["tag:shu:443"] },
    { action: "accept", src: ["group:dns-users"], dst: ["tag:shupi:53"] },
    { action: "accept", src: ["tag:shupi"], dst: ["tag:shu:22"] },
  ])
  assert.deepEqual(policy.tagOwners, {
    "tag:admin": ["autogroup:admin"],
    "tag:personal": ["autogroup:admin"],
    "tag:shupi": ["autogroup:admin"],
    "tag:shulab": ["autogroup:admin"],
    "tag:shu": ["autogroup:admin"],
    "tag:shuwin": ["autogroup:admin"],
  })
  assert.deepEqual(policy.groups, { "group:dns-users": [] })
  assert.deepEqual(policy.nodeAttrs, [{ target: ["tag:admin"], attr: ["funnel"] }])
})

test("prepared SSH candidate narrows shupi only and includes network/account regression expectations", () => {
  const policy = preparedPolicy()
  assert.deepEqual(policy.ssh, [
    { action: "accept", src: ["tag:admin"], dst: ["tag:shupi"], users: ["shu", "root"] },
    {
      action: "accept",
      src: ["tag:admin"],
      dst: ["tag:shulab"],
      users: ["shu", "root", "autogroup:nonroot"],
    },
  ])
  assert.ok(
    policy.tests.some(
      (t: any) =>
        t.src === "tag:admin" &&
        t.accept?.includes("tag:shupi:22") &&
        t.accept?.includes("tag:shulab:22")
    )
  )
  assert.ok(
    policy.tests.some(
      (t: any) =>
        t.src === "tag:personal" &&
        t.deny?.includes("tag:shupi:22") &&
        t.deny?.includes("tag:shu:22")
    )
  )
  assert.ok(
    policy.tests.some(
      (t: any) =>
        t.src === "tag:shupi" &&
        t.deny?.includes("tag:shulab:22") &&
        t.deny?.includes("tag:shuwin:22")
    )
  )
  assert.deepEqual(policy.sshTests, [
    {
      src: "tag:admin",
      dst: ["tag:shupi"],
      accept: ["shu", "root"],
      deny: ["adguardhome", "nobody"],
    },
    { src: "tag:admin", dst: ["tag:shulab"], accept: ["shu", "root"] },
    { src: "tag:personal", dst: ["tag:shupi", "tag:shulab"], deny: ["shu", "root"] },
    { src: "tag:shupi", dst: ["tag:shulab"], deny: ["shu", "root"] },
  ])
})

function fixture() {
  const dir = mkdtempSync(join(tmpdir(), "tailnet-policy-"))
  const bin = join(dir, "bin")
  mkdirSync(bin)
  const state = join(dir, "state.json")
  writeFileSync(
    state,
    JSON.stringify({ policy: baseline, etag: '"old"', calls: [], validation: {}, status: 200 })
  )
  const mock = join(dir, "mock.cjs")
  writeFileSync(
    mock,
    `
const fs = require('node:fs');
const args = process.argv.slice(2), config = fs.readFileSync(0, 'utf8');
const state = JSON.parse(fs.readFileSync(process.env.MOCK_STATE, 'utf8'));
const arg = key => args[args.indexOf(key) + 1];
const method = arg('--request'), url = args.at(-1);
const body = args.includes('--data-binary') ? fs.readFileSync(arg('--data-binary').slice(1), 'utf8') : '';
state.calls.push({ method, url, body, args, config, tokenEnv: process.env.TAILSCALE_API_TOKEN, authEnv: process.env.auth });
let status = state.status, response = '';
if (method === 'GET') { response = state.policy; if (state.readbackFailure && state.etag === '"new"') status = 403; }
else if (url.endsWith('/validate')) { response = typeof state.validation === 'string' ? state.validation : JSON.stringify(state.validation); }
else {
  if (state.writeStatus) status = state.writeStatus;
  if (status === 200 && state.timeout !== 'before') {
    state.policy = state.readbackDrift ? 'unexpected policy' : state.readbackPolicy ?? (state.reformat ? (body.includes('"tests"') ? state.formattedCandidate : '/* server */ { "acls" : [], }') : body);
    state.etag = '"new"';
  }
}
fs.writeFileSync(process.env.MOCK_STATE + '.next', JSON.stringify(state));
fs.renameSync(process.env.MOCK_STATE + '.next', process.env.MOCK_STATE);
if (state.timeout && method === 'POST' && !url.endsWith('/validate')) process.exit(28);
if (state.interrupted && method === 'POST' && !url.endsWith('/validate')) process.exit(143);
fs.writeFileSync(arg('--dump-header'), 'HTTP/1.1 ' + status + ' OK\\r\\n' + (state.noEtag ? '' : 'eTaG: ' + state.etag + '\\r\\n') + '\\r\\n');
fs.writeFileSync(arg('--output'), response);
process.stdout.write(String(status));
if (state.waitForSignal && method === 'POST' && !url.endsWith('/validate')) setTimeout(() => process.exit(0), 500);
`
  )
  writeFileSync(
    join(bin, "curl"),
    `#!/bin/sh\nexec '${process.execPath.replaceAll("'", "'\\''")}' '${mock}' "$@"\n`
  )
  chmodSync(join(bin, "curl"), 0o700)
  const env: NodeJS.ProcessEnv = {
    ...process.env,
    PATH: `${bin}:${process.env.PATH}`,
    MOCK_STATE: state,
    TAILSCALE_TAILNET: "example.com",
    TAILSCALE_API_TOKEN: "secret-test-token",
  }
  const run = (...args: string[]) => spawnSync("bash", [script, ...args], { env, encoding: "utf8" })
  const get = () => JSON.parse(readFileSync(state, "utf8"))
  const set = (patch: object) => writeFileSync(state, JSON.stringify({ ...get(), ...patch }))
  return {
    dir,
    env,
    run,
    get,
    set,
    prefix: join(dir, "live"),
    review: join(dir, "review.json"),
    candidate: join(dir, "candidate.hujson"),
    cleanup: () => rmSync(dir, { recursive: true, force: true }),
  }
}

test("export preserves HuJSON, quoted ETag and private identity metadata without publishing", () => {
  const f = fixture()
  try {
    const result = f.run("export", f.prefix)
    assert.equal(result.status, 0, result.stderr)
    assert.equal(readFileSync(`${f.prefix}.hujson`, "utf8"), baseline)
    assert.equal(readFileSync(`${f.prefix}.etag`, "utf8"), '"old"\n')
    assert.equal(
      JSON.parse(readFileSync(`${f.prefix}.metadata.json`, "utf8")).tailnet,
      "example.com"
    )
    for (const suffix of [".hujson", ".etag", ".metadata.json"])
      assert.equal(statSync(f.prefix + suffix).mode & 0o777, 0o600)
    assert.deepEqual(
      f.get().calls.map((c: any) => c.method),
      ["GET"]
    )
  } finally {
    f.cleanup()
  }
})

function reviewed(f: ReturnType<typeof fixture>) {
  assert.equal(f.run("export", f.prefix).status, 0)
  writeFileSync(f.candidate, candidate)
  const result = f.run(
    "validate",
    f.candidate,
    "--baseline-prefix",
    f.prefix,
    "--review-file",
    f.review
  )
  assert.equal(result.status, 0, result.stderr)
}
function apply(f: ReturnType<typeof fixture>) {
  return f.run(
    "apply",
    f.candidate,
    "--if-match-file",
    `${f.prefix}.etag`,
    "--review-file",
    f.review
  )
}

test("server HuJSON formatting is tolerated by readback, read-only verification and guarded rollback", () => {
  const f = fixture()
  try {
    reviewed(f)
    f.set({
      reformat: true,
      formattedCandidate: '/* server formatting */\n{\n\t"acls": [],\n\t"tests": [],\n}\n',
    })
    assert.equal(apply(f).status, 0)
    const writesBefore = f
      .get()
      .calls.filter((c: any) => c.method === "POST" && c.url.endsWith("/acl")).length
    assert.equal(f.run("verify", "--review-file", f.review).status, 0)
    assert.equal(
      f.get().calls.filter((c: any) => c.method === "POST" && c.url.endsWith("/acl")).length,
      writesBefore
    )
    assert.equal(f.run("rollback", "--review-file", f.review).status, 0)
    const writes = f.get().calls.filter((c: any) => c.method === "POST" && c.url.endsWith("/acl"))
    assert.equal(writes.length, 2)
    assert.ok(writes[1].args.includes('If-Match: "new"'))
  } finally {
    f.cleanup()
  }
})

test("format comparison preserves quoted URLs, comment-like strings, escapes and exact number tokens", () => {
  const f = fixture()
  try {
    assert.equal(f.run("export", f.prefix).status, 0)
    const data =
      '{"acls":[],"tests":[],"data":"https://example.test/a,}/* text */\\\"quote\\\"", "value":9007199254740993}'
    writeFileSync(f.candidate, data)
    assert.equal(
      f.run("validate", f.candidate, "--baseline-prefix", f.prefix, "--review-file", f.review)
        .status,
      0
    )
    f.set({ readbackPolicy: "/* leading */\n" + data.slice(0, -1) + ", /* trailing */ }" })
    assert.equal(apply(f).status, 0)
    f.set({ policy: data.replace("9007199254740993", "9007199254740992") })
    assert.notEqual(f.run("verify", "--review-file", f.review).status, 0)
    assert.notEqual(f.run("rollback", "--review-file", f.review).status, 0)
    assert.equal(
      f.get().calls.filter((c: any) => c.method === "POST" && c.url.endsWith("/acl")).length,
      1
    )
  } finally {
    f.cleanup()
  }
})

for (const reply of [
  '{"acls":["changed"],"tests":[]}',
  '{"tests":[],"acls":[]}',
  '{"acls":[],"tests":[],"extra":true}',
  '{"acls":[],"acls":[],"tests":[]}',
  '"not a policy"',
  '{"acls":[]',
  '{"acls":[],"tests":[]} /* unclosed',
]) {
  test(`readback formatting guard fails closed for changed or malformed reply: ${reply}`, () => {
    const f = fixture()
    try {
      reviewed(f)
      f.set({ readbackPolicy: reply })
      assert.notEqual(apply(f).status, 0)
      assert.notEqual(f.run("rollback", "--review-file", f.review).status, 0)
      assert.equal(
        f.get().calls.filter((c: any) => c.method === "POST" && c.url.endsWith("/acl")).length,
        1
      )
    } finally {
      f.cleanup()
    }
  })
}

test("empty successful validation body is accepted", () => {
  const f = fixture()
  try {
    f.set({ validation: "" })
    reviewed(f)
    assert.equal(apply(f).status, 0)
  } finally {
    f.cleanup()
  }
})

test("review, diff, conditional apply and rollback preserve exact bytes and private snapshots", () => {
  const f = fixture()
  try {
    reviewed(f)
    assert.equal(f.run("diff", f.candidate).status, 0)
    assert.equal(
      f.get().calls.filter((c: any) => c.method === "POST" && !c.url.endsWith("/validate")).length,
      0
    )
    const review = JSON.parse(readFileSync(f.review, "utf8"))
    for (const path of [f.review, review.candidate_snapshot, review.baseline_snapshot])
      assert.equal(statSync(path).mode & 0o777, 0o600)
    assert.equal(statSync(resolve(review.candidate_snapshot, "..")).mode & 0o777, 0o700)
    const result = apply(f)
    assert.equal(result.status, 0, result.stderr)
    assert.equal(f.get().policy, candidate)
    const rollback = f.run("rollback", "--review-file", f.review)
    assert.equal(rollback.status, 0, rollback.stderr)
    assert.equal(f.get().policy, baseline)
    const writes = f
      .get()
      .calls.filter((c: any) => c.method === "POST" && !c.url.endsWith("/validate"))
    assert.ok(writes[0].args.includes('If-Match: "old"'))
    assert.ok(writes[1].args.includes('If-Match: "new"'))
    for (const call of f.get().calls) {
      assert.equal(call.tokenEnv, undefined)
      assert.equal(call.authEnv, undefined)
      assert.ok(!JSON.stringify(call.args).includes("secret-test-token"))
      assert.ok(call.config.includes("Authorization: Bearer secret-test-token"))
      assert.ok(!call.args.includes("-L"))
      assert.ok(call.args.includes("--max-time"))
    }
    assert.ok(!result.stdout.includes("secret-test-token"))
    assert.ok(!result.stderr.includes("secret-test-token"))
  } finally {
    f.cleanup()
  }
})

for (const diagnostics of [
  { errors: ["bad"] },
  { warnings: ["warning"] },
  { message: "failed" },
  { tests: [{ error: "denied" }] },
  "not JSON",
  '{"errors":["bad"]}\n{}',
  [],
  { errors: {}, warnings: [] },
]) {
  test(`validation fails closed: ${JSON.stringify(diagnostics)}`, () => {
    const f = fixture()
    try {
      assert.equal(f.run("export", f.prefix).status, 0)
      writeFileSync(f.candidate, candidate)
      f.set({ validation: diagnostics })
      assert.notEqual(
        f.run("validate", f.candidate, "--baseline-prefix", f.prefix, "--review-file", f.review)
          .status,
        0
      )
      assert.equal(
        f.get().calls.filter((c: any) => c.url.endsWith("/acl") && c.method === "POST").length,
        0
      )
    } finally {
      f.cleanup()
    }
  })
}

for (const mode of [
  "candidate",
  "baseline",
  "snapshot",
  "metadata",
  "identity",
  "etag",
  "review-overwrite",
  "rollback-drift",
  "readback-drift",
]) {
  test(`refuses mutation or drift: ${mode}`, () => {
    const f = fixture()
    try {
      reviewed(f)
      if (mode === "candidate") writeFileSync(f.candidate, baseline)
      if (mode === "baseline") writeFileSync(`${f.prefix}.hujson`, candidate)
      if (mode === "snapshot")
        writeFileSync(JSON.parse(readFileSync(f.review, "utf8")).candidate_snapshot, baseline)
      if (mode === "metadata") writeFileSync(`${f.prefix}.metadata.json`, "{}")
      if (mode === "identity") f.env.TAILSCALE_TAILNET = "another.com"
      if (mode === "etag") writeFileSync(`${f.prefix}.etag`, '"different"')
      if (mode === "review-overwrite") {
        assert.notEqual(
          f.run("validate", f.candidate, "--baseline-prefix", f.prefix, "--review-file", f.review)
            .status,
          0
        )
      } else if (mode === "rollback-drift") {
        assert.equal(apply(f).status, 0)
        f.set({ policy: "third party" })
        assert.notEqual(f.run("rollback", "--review-file", f.review).status, 0)
      } else if (mode === "readback-drift") {
        f.set({ readbackDrift: true })
        assert.notEqual(apply(f).status, 0)
      } else assert.notEqual(apply(f).status, 0)
      const count = f
        .get()
        .calls.filter((c: any) => c.url.endsWith("/acl") && c.method === "POST").length
      assert.equal(count, ["rollback-drift", "readback-drift"].includes(mode) ? 1 : 0)
    } finally {
      f.cleanup()
    }
  })
}

for (const status of [400, 401, 403, 412]) {
  test(`HTTP ${status} blocks validation/export and never retries a write`, () => {
    const f = fixture()
    try {
      reviewed(f)
      f.set({ writeStatus: status })
      assert.notEqual(apply(f).status, 0)
      assert.equal(
        f.get().calls.filter((c: any) => c.url.endsWith("/acl") && c.method === "POST").length,
        1
      )
      f.set({ status })
      assert.notEqual(f.run("export", join(f.dir, "failed")).status, 0)
      assert.notEqual(
        f.run(
          "validate",
          f.candidate,
          "--baseline-prefix",
          f.prefix,
          "--review-file",
          join(f.dir, "failed-review")
        ).status,
        0
      )
    } finally {
      f.cleanup()
    }
  })
}

for (const timeout of ["before", "after"]) {
  test(`timeout ${timeout} commit is unknown-outcome; export reconciles without retry`, () => {
    const f = fixture()
    try {
      reviewed(f)
      f.set({ timeout })
      const result = apply(f)
      assert.notEqual(result.status, 0)
      assert.match(result.stderr, /unknown-outcome/)
      assert.equal(
        f.get().calls.filter((c: any) => c.url.endsWith("/acl") && c.method === "POST").length,
        1
      )
      f.set({ timeout: null })
      const prefix = join(f.dir, "reconciled")
      assert.equal(f.run("export", prefix).status, 0)
      assert.equal(
        readFileSync(prefix + ".hujson", "utf8"),
        timeout === "before" ? baseline : candidate
      )
    } finally {
      f.cleanup()
    }
  })
}

test("missing credentials, unsafe input, missing ETag and existing artifacts fail safely", () => {
  const f = fixture()
  try {
    for (const [key, value] of [
      ["TAILSCALE_TAILNET", ""],
      ["TAILSCALE_API_TOKEN", ""],
      ["TAILSCALE_API_TOKEN", "bad\nheader"],
      ["TAILSCALE_TAILNET", "../other"],
    ]) {
      const original = f.env[key]
      f.env[key] = value
      assert.notEqual(f.run("export", f.prefix).status, 0)
      f.env[key] = original
    }
    assert.equal(f.get().calls.length, 0)
    f.set({ noEtag: true })
    assert.notEqual(f.run("export", f.prefix).status, 0)
    f.set({ noEtag: false })
    assert.equal(f.run("export", f.prefix).status, 0)
    assert.notEqual(f.run("export", f.prefix).status, 0)
    writeFileSync(f.candidate, candidate)
    assert.notEqual(f.run("apply", f.candidate).status, 0)
    assert.notEqual(f.run("rollback").status, 0)
  } finally {
    f.cleanup()
  }
})

test("private parent required, symlink artifacts never overwritten, xtrace and saved artifacts do not leak token", () => {
  const f = fixture()
  try {
    const publicDir = join(f.dir, "public")
    mkdirSync(publicDir)
    chmodSync(publicDir, 0o755)
    assert.notEqual(f.run("export", join(publicDir, "live")).status, 0)
    const target = join(f.dir, "keep")
    writeFileSync(target, "do not touch")
    symlinkSync(target, f.prefix + ".hujson")
    assert.notEqual(f.run("export", f.prefix).status, 0)
    assert.equal(readFileSync(target, "utf8"), "do not touch")
    rmSync(f.prefix + ".hujson")
    const traced = spawnSync("bash", ["-ax", script, "export", f.prefix], {
      env: { ...f.env, auth: "preexisting-export" },
      encoding: "utf8",
    })
    assert.equal(traced.status, 0, traced.stderr)
    assert.ok(!traced.stderr.includes("secret-test-token"))
    writeFileSync(f.candidate, candidate)
    assert.equal(
      f.run("validate", f.candidate, "--baseline-prefix", f.prefix, "--review-file", f.review)
        .status,
      0
    )
    const review = JSON.parse(readFileSync(f.review, "utf8"))
    for (const path of [
      f.review,
      f.prefix + ".metadata.json",
      f.prefix + ".etag",
      review.candidate_snapshot,
      review.baseline_snapshot,
    ]) {
      assert.ok(!readFileSync(path, "utf8").includes("secret-test-token"))
    }
    assert.ok(!readdirSync(f.dir).some((name) => name.startsWith(".tailnet-artifact.")))
  } finally {
    f.cleanup()
  }
})

for (const mode of ["interrupted", "readbackFailure"]) {
  test(`${mode} leaves unknown-outcome with one update only`, () => {
    const f = fixture()
    try {
      reviewed(f)
      f.set({ [mode]: true })
      const result = apply(f)
      assert.notEqual(result.status, 0)
      assert.match(result.stderr, /unknown-outcome/)
      assert.equal(
        f.get().calls.filter((c: any) => c.url.endsWith("/acl") && c.method === "POST").length,
        1
      )
    } finally {
      f.cleanup()
    }
  })
}

test("SIGTERM during committed write reports unknown-outcome and performs no retry", async () => {
  const f = fixture()
  let child: ReturnType<typeof spawn> | undefined
  try {
    reviewed(f)
    f.set({ waitForSignal: true })
    child = spawn(
      "bash",
      [
        script,
        "apply",
        f.candidate,
        "--if-match-file",
        f.prefix + ".etag",
        "--review-file",
        f.review,
      ],
      { env: f.env }
    )
    let stderr = ""
    child.stderr!.on("data", (chunk) => {
      stderr += chunk
    })
    const closed = new Promise((resolve) => child!.on("close", (code) => resolve(code)))
    let observed = false
    for (let attempt = 0; attempt < 200; attempt++) {
      if (f.get().calls.some((c: any) => c.method === "POST" && c.url.endsWith("/acl"))) {
        observed = true
        break
      }
      await new Promise((resolve) => setTimeout(resolve, 10))
    }
    assert.ok(observed, "mock did not receive publish")
    child.kill("SIGTERM")
    assert.notEqual(await closed, 0)
    assert.match(stderr, /unknown-outcome/)
    assert.equal(
      f.get().calls.filter((c: any) => c.method === "POST" && c.url.endsWith("/acl")).length,
      1
    )
    assert.equal(f.get().policy, candidate)
  } finally {
    child?.kill("SIGKILL")
    f.cleanup()
  }
})
