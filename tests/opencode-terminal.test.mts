import assert from "node:assert/strict"
import { existsSync, mkdtempSync, rmSync, symlinkSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import test from "node:test"
import {
  cleanText,
  createTerminalContext,
  rootTransition,
} from "../modules/home-manager/core/opencode/config/terminal/terminal-context.mts"
import type { RootState } from "../modules/home-manager/core/opencode/config/terminal/terminal-context.mts"

test("an invalid notification token cannot select a pane or execute a command", async () => {
  const root = mkdtempSync(join(tmpdir(), "pane-test-"))
  let commands = 0
  const context = createTerminalContext({
    stateDirectory: root,
    run: () => {
      commands++
      throw new Error("unexpected command")
    },
  })
  try {
    for (const token of ["../owner", "$(touch injected)", "", "not-a-token"]) {
      await assert.rejects(context.focus(token), /Invalid notification token/)
    }
    assert.equal(commands, 0)
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

test("terminal labels cannot carry control sequences or tmux format expressions", () => {
  assert.equal(cleanText("\x1b[31mTitle\x1b[0m\n\x07#(touch bad)"), "Title(touch bad)")
  assert.equal(cleanText("x".repeat(200)).length, 160)
})

test("a symlinked state record is not followed", async () => {
  const root = mkdtempSync(join(tmpdir(), "pane-test-"))
  const token = "00000000-0000-4000-8000-000000000001"
  try {
    symlinkSync("/etc/passwd", join(root, `event-${token}.json`))
    const context = createTerminalContext({ stateDirectory: root })
    await assert.rejects(context.focus(token), /ELOOP/)
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

test("child and background root events cannot steal the selected root's title or state", () => {
  const root: RootState = { id: "ses_root", title: "Real task", status: "working", pending: [] }
  assert.deepEqual(
    rootTransition(root, {
      type: "session.updated",
      properties: { info: { id: "ses_child", parentID: "ses_root", title: "Child" } },
    }),
    root
  )
  assert.deepEqual(
    rootTransition(root, {
      type: "session.status",
      properties: { sessionID: "ses_other", status: { type: "idle" } },
    }),
    root
  )
  assert.equal(
    rootTransition(root, {
      type: "session.updated",
      properties: { info: { id: "ses_root", title: "Renamed task" } },
    }).title,
    "Renamed task"
  )
})

test("permission remains waiting until its explicit reply, not an unrelated busy event", () => {
  let root: RootState = { id: "ses_root", title: "Task", status: "working", pending: [] }
  root = rootTransition(root, {
    type: "permission.asked",
    properties: { sessionID: "ses_root", id: "per_1" },
  })
  assert.equal(root.status, "needs_input")
  root = rootTransition(root, {
    type: "session.status",
    properties: { sessionID: "ses_root", status: { type: "busy" } },
  })
  assert.equal(root.status, "needs_input")
  root = rootTransition(root, {
    type: "permission.replied",
    properties: { sessionID: "ses_root", requestID: "per_1" },
  })
  assert.equal(root.status, "working")
})

test("cancelling a turn stays idle rather than displaying a false completion", () => {
  const root: RootState = { id: "ses_root", title: "Task", status: "working", pending: [] }
  const cancelled = rootTransition(root, {
    type: "session.error",
    properties: { sessionID: "ses_root", error: { name: "MessageAbortedError" } },
  })
  assert.equal(
    rootTransition(cancelled, { type: "session.idle", properties: { sessionID: "ses_root" } })
      .status,
    "idle"
  )
})

test("doctor does not create private state, focus windows, or request native access", () => {
  const root = mkdtempSync(join(tmpdir(), "pane-test-"))
  const stateDirectory = join(root, "absent-state")
  try {
    const context = createTerminalContext({
      stateDirectory,
      run() {
        throw new Error("unexpected native command")
      },
    })
    assert.equal(context.doctor().state, "absent")
    assert.equal(existsSync(stateDirectory), false)
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})
