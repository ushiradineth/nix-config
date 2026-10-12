"""Installed-helper smoke; exact PNG transport is separate from semantic image inspection."""

import argparse
import base64
from concurrent.futures import ThreadPoolExecutor
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import threading
import uuid


FIXTURE = Path(__file__).resolve().parent / "fixtures/agent-browser/index.html"
PNG = b"\x89PNG\r\n\x1a\n"


def invoke(helper, request=None):
    argv = [helper] if request else [helper, "--health"]
    result = subprocess.run(argv, input=json.dumps(request) if request else None,
                            capture_output=True, text=True, timeout=30)
    response = json.loads(result.stdout)
    if result.returncode or not response.get("ok") or response.get("truncated"):
        raise RuntimeError(f"helper failed: {response.get('error', 'runtime/truncated')}")
    return response


def text(response, field):
    return response["browser"]["data"][field]


def require(actual, expected):
    if actual != expected:
        raise AssertionError(f"Expected {expected!r}, got {actual!r}")


def retrieve(response, workspace, expected_dimensions):
    artifact = response["artifact"]
    data = base64.b64decode(artifact["base64"], validate=True)
    require(len(data), artifact["size"])
    require(hashlib.sha256(data).hexdigest(), artifact["sha256"])
    require(data[:8], PNG)
    require(data[12:16], b"IHDR")
    require(struct.unpack(">II", data[16:24]), expected_dimensions)
    name = artifact["name"]
    if Path(name).name != name or not name.endswith(".png"):
        raise AssertionError("Unsafe artifact name")
    path = workspace / name
    with path.open("xb") as stream:
        stream.write(data)
    path.chmod(0o600)
    return {"relative_path": name, "size": len(data), "sha256": artifact["sha256"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--local", action="store_true", required=True)
    options = parser.parse_args()
    helper = shutil.which("agent-browser-task") if options.local else None
    if not helper:
        print(json.dumps({"status": "needs_validation", "reason": "agent-browser-task is not installed"}))
        return 2
    try:
        health = invoke(helper)
        require(health["compatible"], True)
        require(health["browser_runtime_available"], True)
    except (RuntimeError, OSError, ValueError, subprocess.TimeoutExpired, AssertionError) as error:
        print(json.dumps({"status": "needs_validation", "reason": str(error)}))
        return 2

    page = FIXTURE.read_bytes()
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == "/favicon.ico":
                self.send_response(204)
                self.end_headers()
                return
            if self.path not in {"/", "/next"}:
                self.send_error(404)
                return
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(page)))
            self.end_headers()
            self.wfile.write(page)

        def log_message(self, format, *args):
            pass

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    url = f"http://127.0.0.1:{server.server_port}/"
    run_id = "smoke-" + uuid.uuid4().hex
    sessions = [{"caller": caller, "run_id": run_id, "session_id": marker,
                 "mode": "local-test", "initial_url": url, "domains": ["127.0.0.1"]}
                for caller, marker in (("opencode", "alpha"), ("paperclip", "beta"))]
    cleanup, evidence = [], []
    status, failure = "pass", None
    try:
        thread.start()
        print(json.dumps({"fixture_url": url, "request": {**sessions[0], "command": "open", "args": [url]}}))
        with tempfile.TemporaryDirectory(prefix="agent-browser-smoke-") as temporary:
            workspace = Path(temporary)
            workspace.chmod(0o700)
            def flow(scope):
                def call(command, args):
                    return invoke(helper, {**scope, "command": command, "args": args})
                marker = scope["session_id"]
                call("open", [url])
                if "Browser fixture" not in text(call("snapshot", []), "snapshot"):
                    raise AssertionError("Fixture missing from snapshot")
                require(text(call("get", ["text", "#marker"]), "text"), "unset")
                call("fill", ["#name", "   "])
                call("click", ["#submit"])
                require(text(call("get", ["text", "#status"]), "text"), "Name required")
                require(text(call("get", ["text", "#marker"]), "text"), "unset")
                call("fill", ["#name", marker])
                call("click", ["#submit"])
                require(text(call("get", ["text", "#status"]), "text"), "Saved: " + marker)
                shots = []
                for label, dimensions in (("desktop", (1280, 800)), ("mobile", (390, 844))):
                    call("viewport", list(map(str, dimensions)))
                    name = f"{marker}-{label}.png"
                    call("screenshot", [name])
                    shots.append(retrieve(call("artifact-read", [name]), workspace, dimensions))
                call("click", ["#next"])
                require(text(call("get", ["url"]), "url"), url + "next")
                require(text(call("get", ["text", "#route"]), "text"), "Next page")
                require(text(call("get", ["text", "#marker"]), "text"), marker)
                console = call("console", [])["browser"]["data"]
                errors = call("errors", [])["browser"]["data"]
                messages = console.get("messages", console.get("logs"))
                if not isinstance(errors.get("errors"), list) or not isinstance(messages, list):
                    raise AssertionError("Unknown console/errors schema; not complete evidence")
                if errors["errors"]:
                    raise AssertionError("Fixture reported page errors")
                if any(not isinstance(entry, dict) or entry.get("type", entry.get("level")) == "error" for entry in messages):
                    raise AssertionError("Fixture reported console errors")
                return {"caller": scope["caller"], "marker": marker, "artifacts": shots}
            with ThreadPoolExecutor(max_workers=2) as pool:
                evidence = list(pool.map(flow, sessions))
            # Read both again after both writes/navigation, so cross-session leakage cannot pass.
            for scope in sessions:
                require(text(invoke(helper, {**scope, "command": "get", "args": ["text", "#marker"]}), "text"), scope["session_id"])
    except (RuntimeError, OSError, ValueError, KeyError, struct.error, subprocess.TimeoutExpired, AssertionError) as error:
        status, failure = "fail", str(error)
    finally:
        for scope in sessions:
            try:
                response = invoke(helper, {**scope, "command": "close", "args": []})
                require(response["closed"], True)
                cleanup.append({"session_id": scope["session_id"], "status": "closed"})
            except (RuntimeError, OSError, ValueError, KeyError, subprocess.TimeoutExpired, AssertionError):
                cleanup.append({"session_id": scope["session_id"], "status": "needs_validation"})
                status = "fail"
        if thread.is_alive():
            server.shutdown()
            thread.join(timeout=3)
        server.server_close()
    print(json.dumps({"status": status, "failure": failure, "evidence": evidence,
                      "cleanup": cleanup, "server_closed": not thread.is_alive(),
                      "visual_inspection": "needs_validation", "native_ssh": "needs_validation",
                      "artifact_lifecycle": "disposable exact-byte retrieval; no image rendering claim"}))
    return 0 if status == "pass" and not thread.is_alive() else 1


if __name__ == "__main__":
    sys.exit(main())
