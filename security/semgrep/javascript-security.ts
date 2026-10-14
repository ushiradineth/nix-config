// Static scanner fixtures only. Never import or execute.
import { exec as run, execFile } from "node:child_process"
import * as cp from "child_process"
import * as nodeCp from "node:child_process"
import * as https from "node:https"
import { connect as tlsConnect } from "node:tls"

function handler(req, res) {
  // ruleid: node-request-to-shell
  run(req.query.command)
  const command = req.body.command
  const copied = command
  // ruleid: node-request-to-shell
  cp.exec(copied)
  // ruleid: node-request-to-shell
  cp.spawn("sh", ["-c", req.params.command])
  // ruleid: node-request-to-shell
  nodeCp.exec(req.query.command)
  // ruleid: node-request-to-shell
  nodeCp.spawn(req.body.command, [], { shell: true })
  // ok: node-request-to-shell
  execFile("printf", [req.query.value])
  // ok: node-request-to-shell
  cp.spawn("printf", [req.body.value])
  // ok: node-request-to-shell
  nodeCp.spawn("printf", [req.body.value], { shell: false })
  // ok: node-request-to-shell
  run("printf fixed")
}

// ruleid: node-disabled-tls-verification
https.request({ hostname: "example.invalid", rejectUnauthorized: false })
const insecure = { rejectUnauthorized: false }
// ruleid: node-disabled-tls-verification
tlsConnect(insecure)
// ruleid: node-disabled-tls-verification
new https.Agent({ rejectUnauthorized: false })
// ok: node-disabled-tls-verification
https.request({ rejectUnauthorized: true })
// ok: node-disabled-tls-verification
tlsConnect({ host: "example.invalid" })
// ok: node-disabled-tls-verification
unrelatedClient({ rejectUnauthorized: false })
