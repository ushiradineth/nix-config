"""Exercise the JSON stdin CLI using a disposable executable browser fixture."""

import base64
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / (
    "modules/home-manager/core/opencode/config/skills/browser-workflow/scripts/browser_task.py"
)
PNG = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aRZkAAAAASUVORK5CYII=")
FAKE = r'''
import base64, json, os, pathlib, sys, time
if sys.argv[1:] == ["--version"]:
    print("agent-browser 0.38.1")
    sys.exit(0)
options = {}
args = sys.argv[1:]
while args[0].startswith("--"):
    key = args.pop(0)
    if key in {"--json", "--content-boundaries", "--no-webmcp"}:
        options[key] = True
    else:
        options[key] = args.pop(0)
home = pathlib.Path(os.environ["HOME"])
if "socket-limit" in args[-1]:
    socket_root = pathlib.Path(os.environ.get("AGENT_BROWSER_SOCKET_DIR", home / ".agent-browser"))
    socket_path = socket_root / options["--namespace"] / (options["--session"] + ".sock")
    if len(os.fsencode(socket_path)) > 103:
        print(json.dumps({"success": False, "error": "Socket path exceeds macOS limit"}))
        sys.exit(1)
state_path = home / "fake-state.json"
state = json.loads(state_path.read_text()) if state_path.exists() else {"url": "about:blank", "marker": ""}
with pathlib.Path("calls.jsonl").open("a") as log:
    log.write(json.dumps({"options": options, "args": args, "env": dict(os.environ), "pid": os.getpid(), "config": json.loads(pathlib.Path(options["--config"]).read_text())}) + "\n")
cmd = args[0]
data = {}
if cmd == "open":
    state["url"] = args[1]
    if "redirect" in args[1]: state["url"] = "http://127.0.0.1:9999/escaped"
elif cmd == "get":
    data = {"url": state["url"]} if args[1] == "url" else {"text": state["marker"], "title": "Fixture"}
elif cmd == "fill":
    if args[1] == "#slow": time.sleep(10)
    if args[1] == "#flood":
        sys.stdout.write("x" * 200000)
        sys.stdout.flush()
        time.sleep(10)
    if args[1] == "#stderr":
        sys.stderr.write("x" * 200000)
        sys.stderr.flush()
        time.sleep(10)
    if args[1] == "#malformed":
        print("not json")
        sys.exit(0)
    if args[1] == "#fail":
        print(json.dumps({"success": False, "error": "fixture failure"}))
        sys.exit(1)
    state["marker"] = args[2]
elif cmd == "snapshot":
    data = {} if state["marker"] == "empty-snapshot" else {"snapshot": "[untrusted] Fixture " + state["marker"]}
    if state["marker"] == "truncated-snapshot": data = {"snapshot": "partial", "truncated": True}
    if state["marker"] == "long-snapshot": data = {"snapshot": "x" * 25000}
elif cmd == "screenshot":
    pathlib.Path(args[1]).write_bytes(base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aRZkAAAAASUVORK5CYII="))
elif cmd == "close":
    if state["marker"] == "refuse-close":
        print(json.dumps({"success": False, "error": "fixture cleanup failure"}))
        sys.exit(1)
    state = {"url": "about:blank", "marker": ""}
state_path.write_text(json.dumps(state))
print(json.dumps({"success": True, "data": data}))
'''


class BrowserTaskTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.browser = self.root / "fake-browser"
        self.browser.write_text("#!" + sys.executable + "\n" + FAKE)
        self.browser.chmod(0o700)
        self.tasks = self.root / "tasks"
        self.request = {
            "caller": "opencode", "run_id": "run-1", "session_id": "session-1",
            "mode": "local-test", "initial_url": "http://127.0.0.1:8123/",
            "domains": ["127.0.0.1"], "command": "open",
            "args": ["http://127.0.0.1:8123/"],
        }

    def cli(self, request=None, raw=None, extra=(), env=None):
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--browser", str(self.browser),
             "--task-root", str(self.tasks), *extra],
            input=raw if raw is not None else json.dumps(request or self.request),
            capture_output=True, text=True, timeout=12, env=env,
        )

    def ok(self, **updates):
        result = self.cli({**self.request, **updates})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        payload = json.loads(result.stdout)
        self.assertTrue(payload["ok"])
        return payload

    def denied(self, error=None, **updates):
        result = self.cli({**self.request, **updates})
        self.assertNotEqual(result.returncode, 0, result.stdout)
        payload = json.loads(result.stdout)
        self.assertFalse(payload["ok"])
        if error:
            self.assertEqual(payload["error"], error)
        return payload

    def logs(self):
        return [json.loads(line) for path in self.tasks.glob("*/calls.jsonl")
                for line in path.read_text().splitlines()]

    def test_unknown_mode_is_structured_error(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT)], input=json.dumps({
                "caller": "opencode", "run_id": "run-1", "session_id": "session-1",
                "mode": "authenticated", "initial_url": "https://example.com/",
                "domains": ["example.com"], "command": "snapshot", "args": [],
            }), text=True, capture_output=True, timeout=10,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(json.loads(result.stdout)["error"], "invalid_mode")

    def test_navigation_snapshot_and_targeted_close(self):
        opened = self.ok()
        result = self.ok(command="snapshot", args=[])
        self.assertIn("Fixture", result["browser"]["data"]["snapshot"])
        self.assertTrue(result["untrusted"])
        self.assertEqual(result["session"], opened["session"])
        self.ok(command="close", args=[])
        self.assertEqual(self.logs()[-1]["args"], ["close"])
        self.denied("session_closed", command="snapshot", args=[])

    def test_private_sessions_fit_macos_socket_limit(self):
        with tempfile.TemporaryDirectory(prefix="abt", dir="/private/tmp" if sys.platform == "darwin" else "/tmp") as directory:
            self.tasks = Path(directory).resolve() / "tasks"
            url = "http://127.0.0.1:8123/socket-limit"
            self.ok(initial_url=url, args=[url])
            self.ok(initial_url=url, command="snapshot", args=[])
            self.ok(initial_url=url, command="close", args=[])

    def test_scope_is_immutable_including_initial_url(self):
        self.ok()
        for updates in ({"mode": "public-read", "initial_url": "https://example.com/", "domains": ["example.com"]},
                        {"initial_url": "http://127.0.0.1:8123/new"}):
            self.denied("scope_changed", command="snapshot", args=[], **updates)

    def test_local_exact_origin_before_read_and_mutation(self):
        self.ok()
        self.denied("url_out_of_scope", args=["http://127.0.0.1:9999/"])
        for command, args in (("snapshot", []), ("fill", ["#name", "x"]),
                              ("artifact-read", ["page.png"])):
            self.request["session_id"] = command
            opened = self.ok()
            home = next(call["env"]["HOME"] for call in self.logs()
                        if call["options"]["--session"] == opened["session"])
            task = Path(home) / "fake-state.json"
            task.write_text(json.dumps({"url": "http://127.0.0.1:9999/", "marker": "private"}))
            result = self.denied("url_out_of_scope", command=command, args=args)
            self.assertNotIn("private", json.dumps(result))
        self.assertNotIn(["snapshot"], [call["args"] for call in self.logs()])

    def test_redirect_closes_own_session_and_hides_response(self):
        self.ok()
        self.denied("url_out_of_scope", args=["http://127.0.0.1:8123/redirect"])
        self.assertEqual(self.logs()[-1]["args"], ["close"])

    def test_public_read_rejects_mutations_and_loopback(self):
        public = {"mode": "public-read", "initial_url": "https://example.com/",
                  "domains": ["example.com"], "args": ["https://example.com/"]}
        self.ok(**public)
        for command, args in (("click", ["@e1"]), ("fill", ["#name", "x"]),
                              ("press", ["Enter"]), ("select", ["#choice", "a"])):
            self.denied("command_denied", **{**public, "command": command, "args": args})
        self.ok(**{**public, "command": "snapshot", "args": []})
        self.denied("invalid_scope", mode="public-read", session_id="loopback")

    def test_bad_urls_domains_and_identity(self):
        for url in ("file:///etc/passwd", "https://a:b@example.com/", "http://127.0.0.1:0/",
                    "http://localhost:8123/", "http://127.0.0.1:8123/\n--cdp"):
            self.denied(initial_url=url, args=[url])
        for domains in (["*"], ["*.example.com"], [], ["127.0.0.1:8123"], ["127.0.0.1,example.com"]):
            self.denied(domains=domains)
        for field in ("caller", "run_id", "session_id"):
            for value in ("../escape", "", "x" * 65, None):
                self.denied(**{field: value})

    def test_extra_flags_and_arbitrary_commands_rejected(self):
        for command in ("eval", "auth", "upload", "webmcp", "connect", "mcp", "batch", "storage", "plugin"):
            self.denied("command_denied", command=command, args=[])
        for flag in ("--profile", "--cdp", "--auto-connect", "--provider", "--restore",
                     "--headers", "--all", "--headed", "--eval", "--config", "--args"):
            self.denied(command="fill", args=["#name", flag])
        self.denied(extra_flags=["--cdp", "9222"])
        self.denied(command="close", args=["--all"])

    def test_json_and_input_bounds(self):
        for raw in ("not json", "[]", '{"mode":"local-test","mode":"public-read"}', "x" * 17000):
            result = self.cli(raw=raw)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(json.loads(result.stdout)["ok"])
        self.denied(command="fill", args=["#name", "x" * 4097])

    def test_clean_config_env_and_owner_only_directories(self):
        env = {**os.environ, "AGENT_BROWSER_PROFILE": "Default", "AGENT_BROWSER_PLUGINS": "evil",
               "HTTP_PROXY": "http://private", "NODE_OPTIONS": "--require evil", "FAKE_TOKEN": "private"}
        result = self.cli(env=env)
        self.assertEqual(result.returncode, 0, result.stdout)
        log = self.logs()[0]
        for key in ("AGENT_BROWSER_PROFILE", "AGENT_BROWSER_PLUGINS", "HTTP_PROXY", "NODE_OPTIONS", "FAKE_TOKEN"):
            self.assertNotIn(key, log["env"])
        self.assertNotEqual(log["env"]["HOME"], os.environ.get("HOME"))
        self.assertEqual(log["config"], {"headed": False, "plugins": [], "extensions": []})
        for flag in ("--namespace", "--session", "--config", "--allowed-domains", "--idle-timeout"):
            self.assertIn(flag, log["options"])
        self.assertEqual(log["options"]["--headed"], "false")
        self.assertEqual(log["options"]["--idle-timeout"], "60s")
        self.assertEqual(log["options"]["--allowed-domains"], "127.0.0.1")
        self.assertEqual(log["options"]["--max-output"], "24000")
        self.assertEqual(log["env"]["AGENT_BROWSER_DEFAULT_TIMEOUT"], "5000")
        self.assertTrue(log["options"]["--no-webmcp"])
        self.assertTrue(log["options"]["--content-boundaries"])
        for directory in [self.tasks, *self.tasks.glob("*"), *self.tasks.glob("*/home")]:
            self.assertEqual(directory.stat().st_mode & 0o777, 0o700)

    def test_artifact_exact_bytes_and_unsafe_paths(self):
        self.ok()
        self.ok(command="screenshot", args=["page.png"])
        result = self.ok(command="artifact-read", args=["page.png"])["artifact"]
        self.assertEqual(base64.b64decode(result["base64"]), PNG)
        self.assertEqual(result["size"], len(PNG))
        self.assertEqual(result["sha256"], hashlib.sha256(PNG).hexdigest())
        for name in ("../page.png", "/tmp/page.png", "sub/page.png", "..", "--all", "x.jpg"):
            self.denied(command="screenshot", args=[name])
            self.denied(command="artifact-read", args=[name])
        artifact = next(self.tasks.glob("*/artifacts/page.png"))
        artifact.unlink()
        artifact.symlink_to(self.browser)
        self.denied("unsafe_file", command="artifact-read", args=["page.png"])
        self.denied("unsafe_file", command="screenshot", args=["page.png"])

    def test_artifact_size_and_signature_bounds(self):
        self.ok()
        self.ok(command="screenshot", args=["page.png"])
        artifact = next(self.tasks.glob("*/artifacts/page.png"))
        artifact.write_bytes(b"not png")
        self.denied("invalid_png", command="artifact-read", args=["page.png"])
        artifact.write_bytes(b"\x89PNG\r\n\x1a\n" + b"x" * (2 * 1024 * 1024))
        self.denied("artifact_too_large", command="artifact-read", args=["page.png"])

    def test_symlink_roots_config_and_scope_rejected(self):
        other = self.root / "other"
        other.mkdir(mode=0o700)
        self.tasks.symlink_to(other, target_is_directory=True)
        self.denied("unsafe_directory")
        self.tasks.unlink()
        self.ok()
        for name in ("scope.json", "config.json"):
            path = next(self.tasks.glob("*/" + name))
            data = path.read_bytes()
            path.unlink()
            path.symlink_to(self.browser)
            self.denied("unsafe_file")
            path.unlink()
            path.write_bytes(data)
            path.chmod(0o600)

    def test_changed_config_and_world_readable_root_rejected(self):
        self.ok()
        next(self.tasks.glob("*/config.json")).write_text('{"headed":true}')
        self.denied("config_changed")
        self.tasks.chmod(0o755)
        self.denied("unsafe_directory")

    def test_concurrent_runs_and_callers_have_separate_storage(self):
        def flow(identity):
            caller, run_id, session_id, marker = identity
            updates = {"caller": caller, "run_id": run_id, "session_id": session_id}
            opened = self.ok(**updates)
            self.ok(**updates, command="fill", args=["#name", marker])
            snapshot = self.ok(**updates, command="snapshot", args=[])
            return opened, snapshot
        identities = [("opencode", "run-1", "same", "alpha"),
                      ("paperclip", "run-1", "same", "beta"),
                      ("opencode", "run-2", "same", "gamma")]
        with ThreadPoolExecutor(max_workers=3) as pool:
            results = list(pool.map(flow, identities))
        self.assertEqual(len({r[0]["session"] for r in results}), 3)
        self.assertEqual(len({call["options"]["--namespace"] for call in self.logs()}), 3)
        for identity, (_, snapshot) in zip(identities, results):
            self.assertEqual(snapshot["browser"]["data"]["snapshot"], "[untrusted] Fixture " + identity[3])

    def test_timeout_output_and_browser_failures_close_only_owned_session(self):
        for selector, error in (("#slow", "timeout"), ("#flood", "output_limit"), ("#stderr", "output_limit"),
                                ("#malformed", "invalid_browser_output"), ("#fail", "browser_failed")):
            self.request["session_id"] = selector[1:]
            self.ok()
            started = time.monotonic()
            self.denied(error, command="fill", args=[selector, "x"], timeout_ms=700)
            self.assertLess(time.monotonic() - started, 4)
            logs = self.logs()
            own = [c for c in logs if c["options"]["--session"] == logs[-1]["options"]["--session"]]
            self.assertEqual(own[-1]["args"], ["close"])
            if selector in {"#slow", "#flood", "#stderr"}:
                pid = next(c["pid"] for c in own if c["args"][0] == "fill")
                with self.assertRaises(ProcessLookupError):
                    os.kill(pid, 0)

    def test_health_is_nonmutating_and_version_matched(self):
        result = self.cli(extra=("--health",))
        self.assertEqual(result.returncode, 0, result.stdout)
        health = json.loads(result.stdout)
        self.assertEqual(health["version"], "0.38.1")
        self.assertTrue(health["compatible"])
        self.assertFalse(self.tasks.exists())
        self.browser.write_text("#!" + sys.executable + '\nprint("agent-browser 9.0.0")\n')
        result = self.cli(extra=("--health",))
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(json.loads(result.stdout)["compatible"])

    def test_public_numeric_loopback_spellings_are_not_public_domains(self):
        for host in ("127.1", "0177.0.0.1", "127.000.000.001", "0x7f.0.0.1"):
            self.denied("invalid_scope", mode="public-read", initial_url="https://" + host + "/",
                        domains=[host], args=["https://" + host + "/"])

    def test_input_deadline_does_not_require_eof(self):
        process = subprocess.Popen([sys.executable, str(SCRIPT)], stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        assert process.stdin is not None and process.stdout is not None and process.stderr is not None
        try:
            process.stdin.write(b"{")
            process.stdin.flush()
            process.wait(timeout=7)
            self.assertEqual(json.loads(process.stdout.read())["error"], "input_timeout")
        finally:
            if process.poll() is None:
                process.kill()
            process.wait()
            process.stdin.close()
            process.stdout.close()
            process.stderr.close()

    def test_installed_wrapper_prohibits_runtime_overrides(self):
        result = self.cli(extra=("--installed",))
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(json.loads(result.stdout)["error"], "runtime_override_denied")
        self.assertFalse(self.tasks.exists())

    def test_version_change_blocks_launch_and_scope_is_not_rewritten(self):
        self.browser.write_text("#!" + sys.executable + '\nprint("agent-browser 9.0.0")\n')
        self.denied("incompatible_browser")
        self.assertFalse(self.tasks.exists())

    def test_shell_metacharacters_are_literal_data(self):
        self.ok()
        value = "$(touch sentinel); `id` & cat /etc/passwd"
        self.ok(command="fill", args=["#name", value])
        result = self.ok(command="get", args=["text", "#name"])
        self.assertEqual(result["browser"]["data"]["text"], value)
        self.assertEqual(next(call["args"] for call in self.logs() if call["args"][0] == "fill"), ["fill", "#name", value])
        self.assertFalse(list(self.root.rglob("sentinel")))

    def test_failure_leaves_other_session_live(self):
        survivor = {"session_id": "survivor"}
        self.ok(**survivor)
        self.ok(**survivor, command="fill", args=["#name", "keep"])
        self.ok()
        result = self.denied("browser_failed", command="fill", args=["#fail", "x"])
        self.assertEqual(result["cleanup"], "complete")
        self.assertEqual(self.ok(**survivor, command="get", args=["text", "#name"])["browser"]["data"]["text"], "keep")

    def test_failed_cleanup_is_not_reported_as_closed(self):
        self.ok()
        self.ok(command="fill", args=["#name", "refuse-close"])
        result = self.denied("browser_failed", command="fill", args=["#fail", "x"])
        self.assertEqual(result["cleanup"], "needs_validation")
        close = self.ok(command="close", args=[])
        self.assertFalse(close["closed"])
        self.assertEqual(close["cleanup"], "needs_validation")

    def test_incomplete_snapshot_is_not_complete_evidence(self):
        self.ok()
        self.ok(command="fill", args=["#name", "empty-snapshot"])
        self.denied("invalid_browser_output", command="snapshot", args=[])

    def test_deep_json_is_a_structured_error(self):
        result = self.cli(raw="[" * 8000 + "0" + "]" * 8000)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(json.loads(result.stdout)["error"], {"invalid_json", "invalid_request"})

    def test_regular_file_stdin_uses_same_json_contract(self):
        path = self.root / "request.json"
        path.write_text(json.dumps({**self.request, "mode": "authenticated"}))
        with path.open("rb") as stream:
            result = subprocess.run([sys.executable, str(SCRIPT)], stdin=stream,
                                    capture_output=True, text=True, timeout=10)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(json.loads(result.stdout)["error"], "invalid_mode")

    def test_public_domain_scope_cannot_be_extended_on_existing_session(self):
        public = {"mode": "public-read", "initial_url": "https://example.com/",
                  "domains": ["example.com"], "args": ["https://example.com/"]}
        self.ok(**public)
        self.denied("scope_changed", **{**public, "domains": ["example.com", "other.net"],
                                       "command": "snapshot", "args": []})

    def test_artifact_hardlinks_and_special_files_are_rejected(self):
        self.ok()
        self.ok(command="screenshot", args=["page.png"])
        artifact = next(self.tasks.glob("*/artifacts/page.png"))
        os.link(artifact, self.root / "linked.png")
        self.denied("unsafe_file", command="artifact-read", args=["page.png"])
        artifact.unlink()
        os.mkfifo(artifact, 0o600)
        self.denied("unsafe_file", command="artifact-read", args=["page.png"])

    def test_truncated_and_long_output_are_marked(self):
        self.ok()
        for marker in ("truncated-snapshot", "long-snapshot"):
            self.ok(command="fill", args=["#name", marker])
            result = self.ok(command="snapshot", args=[])
            self.assertTrue(result["truncated"])


if __name__ == "__main__":
    unittest.main()
