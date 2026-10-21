#!/usr/bin/env python3
"""Task-scoped browser requests. This is a same-user guardrail, not an OS sandbox."""

import argparse
import base64
import fcntl
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import selectors
import stat
import subprocess
import sys
import time
from typing import NoReturn
from urllib.parse import urlsplit


BROWSER = "/opt/homebrew/bin/agent-browser"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# Keep socket ancestry short and stable across local and SSH environments.
ROOT = Path("/private/tmp" if sys.platform == "darwin" else "/tmp") / f"abt-{os.getuid()}"
CONFIG = {"headed": False, "plugins": [], "extensions": []}
MAX_INPUT, MAX_OUTPUT, MAX_ARTIFACT = 16384, 65536, 2 * 1024 * 1024
PNG = b"\x89PNG\r\n\x1a\n"


class Rejected(Exception):
    cleanup: str | None = None


def reject(code) -> NoReturn:
    raise Rejected(code)


def parse_json(data):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                reject("invalid_json")
            result[key] = value
        return result
    try:
        return json.loads(data, object_pairs_hook=unique)
    except (ValueError, UnicodeError, RecursionError):
        reject("invalid_json")


def input_request():
    if stat.S_ISREG(os.fstat(sys.stdin.fileno()).st_mode):
        data = os.read(sys.stdin.fileno(), MAX_INPUT + 1)
        if len(data) > MAX_INPUT:
            reject("input_limit")
        return parse_json(data)
    data = bytearray()
    deadline = time.monotonic() + 5
    with selectors.DefaultSelector() as selector:
        selector.register(sys.stdin.buffer, selectors.EVENT_READ)
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0 or not selector.select(remaining):
                reject("input_timeout")
            chunk = os.read(sys.stdin.fileno(), min(4096, MAX_INPUT + 1 - len(data)))
            if not chunk:
                return parse_json(data)
            data.extend(chunk)
            if len(data) > MAX_INPUT:
                reject("input_limit")


def url_parts(url) -> tuple[str, str, int]:
    if (not isinstance(url, str) or len(url) > 2048 or
            any(ord(c) < 33 or ord(c) == 127 for c in url) or "\\" in url):
        reject("invalid_url")
    try:
        part = urlsplit(url)
        port = part.port
        if (part.scheme not in {"http", "https"} or not part.hostname or
                part.username is not None or part.password is not None or port == 0):
            reject("invalid_url")
        return part.scheme, part.hostname, port or (443 if part.scheme == "https" else 80)
    except ValueError:
        reject("invalid_url")


def public_domain(host):
    try:
        return ipaddress.ip_address(host).is_global
    except ValueError:
        return (re.fullmatch(r"[a-z0-9.-]+\.[a-z]{2,63}", host) is not None
                and not host.endswith((".local", ".localhost", ".internal"))
                and host != "localhost")


def in_scope(url, scope):
    origin = url_parts(url)
    if scope["mode"] == "local-test":
        valid = origin == url_parts(scope["initial_url"])
    else:
        valid = origin[0] == "https" and origin[1] in scope["domains"] and origin[2] == 443
    if not valid:
        reject("url_out_of_scope")


def validate(request):
    required = {"caller", "run_id", "session_id", "mode", "initial_url", "domains", "command", "args"}
    if not isinstance(request, dict) or not required <= request.keys() or request.keys() - required - {"timeout_ms"}:
        reject("invalid_request")
    if not isinstance(request["mode"], str) or request["mode"] not in {"public-read", "local-test"}:
        reject("invalid_mode")
    if not isinstance(request["caller"], str) or request["caller"] not in {"opencode", "paperclip"}:
        reject("invalid_identity")
    for field in ("run_id", "session_id"):
        if not isinstance(request[field], str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}", request[field]):
            reject("invalid_identity")
    domains = request["domains"]
    if (not isinstance(domains, list) or not 1 <= len(domains) <= 8 or
            any(not isinstance(d, str) or len(d) > 253 or
                not re.fullmatch(r"[a-z0-9]+(?:[.-][a-z0-9]+)*", d) for d in domains) or
            len(set(domains)) != len(domains)):
        reject("invalid_scope")
    origin = url_parts(request["initial_url"])
    if request["mode"] == "local-test":
        if origin[0] != "http" or origin[1] != "127.0.0.1" or domains != ["127.0.0.1"]:
            reject("invalid_scope")
    elif any(not public_domain(d) for d in domains):
        reject("invalid_scope")
    in_scope(request["initial_url"], request)
    timeout = request.get("timeout_ms", 20000)
    if type(timeout) is not int or not 500 <= timeout <= 20000:
        reject("invalid_timeout")
    command, args = request["command"], request["args"]
    if not isinstance(command, str) or not isinstance(args, list) or len(args) > 3:
        reject("invalid_command")
    for arg in args:
        if (not isinstance(arg, str) or len(arg) > 4096 or arg.startswith("-") or
                any(ord(c) < 32 or ord(c) == 127 for c in arg)):
            reject("invalid_args")
    counts = {"open": 1, "snapshot": 0, "get": None, "viewport": 2,
              "screenshot": 1, "artifact-read": 1, "console": 0, "errors": 0, "close": 0}
    if request["mode"] == "local-test":
        counts.update({"click": 1, "fill": 2, "check": 1, "uncheck": 1, "select": 2, "drag": 2})
    if command not in counts:
        reject("command_denied")
    if counts[command] is not None and len(args) != counts[command]:
        reject("invalid_args")
    if command == "drag" and any(not arg.strip() for arg in args):
        reject("invalid_args")
    if command == "get" and not (args in [["url"], ["title"]] or
                                 len(args) == 2 and args[0] == "text" and args[1]):
        reject("invalid_args")
    if command == "open":
        in_scope(args[0], request)
    if command == "viewport" and any(not re.fullmatch(r"[0-9]{3,4}", a) or not 240 <= int(a) <= 1920 for a in args):
        reject("invalid_args")
    if command in {"screenshot", "artifact-read"} and not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}\.png", args[0]):
        reject("invalid_artifact")
    return {key: request[key] for key in ("caller", "run_id", "session_id", "mode", "initial_url", "domains")}


def no_links(path):
    for component in (*reversed(path.parents), path):
        if component.is_symlink():
            reject("unsafe_directory")


def private_directory(path):
    no_links(path)
    try:
        path.mkdir(mode=0o700)
    except FileExistsError:
        pass
    info = path.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
        reject("unsafe_directory")


def file_open(path, flags=os.O_RDONLY):
    try:
        fd = os.open(path, flags | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    except OSError:
        reject("unsafe_file")
    info = os.fstat(fd)
    if (not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or
            info.st_nlink != 1 or info.st_mode & 0o077):
        os.close(fd)
        reject("unsafe_file")
    return fd


def read_file(path, limit):
    with os.fdopen(file_open(path), "rb") as stream:
        data = stream.read(limit + 1)
    if len(data) > limit:
        reject("artifact_too_large")
    return data


def write_new(path, data):
    with os.fdopen(file_open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL), "wb") as stream:
        stream.write(data)


def immutable(path, value, error):
    data = json.dumps(value, sort_keys=True).encode()
    if path.exists() or path.is_symlink():
        if read_file(path, MAX_INPUT) != data:
            reject(error)
    else:
        write_new(path, data)


def environment(home, sockets=None):
    env = {"PATH": "/usr/bin:/bin", "HOME": str(home), "TMPDIR": str(home),
             "XDG_CONFIG_HOME": str(home), "XDG_CACHE_HOME": str(home),
             "XDG_DATA_HOME": str(home), "LANG": "en_US.UTF-8", "CI": "true",
             "AGENT_BROWSER_DEFAULT_TIMEOUT": "5000"}
    if sockets is not None:
        env["AGENT_BROWSER_SOCKET_DIR"] = str(sockets)
    return env


def execute(argv, cwd, env, deadline):
    if deadline <= time.monotonic():
        reject("timeout")
    process = subprocess.Popen(argv, cwd=cwd, env=env, stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert process.stdout is not None and process.stderr is not None
    output = bytearray()
    total = 0
    try:
        with selectors.DefaultSelector() as selector:
            for pipe in (process.stdout, process.stderr):
                os.set_blocking(pipe.fileno(), False)
                selector.register(pipe, selectors.EVENT_READ)
            while selector.get_map():
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    reject("timeout")
                for key, _ in selector.select(remaining):
                    chunk = os.read(key.fd, 4096)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        continue
                    total += len(chunk)
                    if total > MAX_OUTPUT:
                        reject("output_limit")
                    if key.fileobj is process.stdout:
                        output.extend(chunk)
            process.wait(timeout=max(0.001, deadline - time.monotonic()))
        return process.returncode, bytes(output)
    except subprocess.TimeoutExpired:
        reject("timeout")
    finally:
        if process.poll() is None:
            # Never signal a process group or an externally owned browser.
            process.kill()
        process.wait()
        process.stdout.close()
        process.stderr.close()


def browser_call(browser, task, scope, token, command, args, deadline):
    argv = [browser, "--config", str(task / "config.json"),
            "--namespace", scope["caller"] + "-" + token[:8], "--session", "t-" + token[:16],
            "--headed", "false", "--no-webmcp", "--json", "--content-boundaries",
            "--max-output", "24000", "--allowed-domains", ",".join(scope["domains"]),
            "--idle-timeout", "60s", "--screenshot-format", "png"]
    if browser == BROWSER:
        if not os.access(CHROME, os.X_OK):
            reject("browser_runtime_missing")
        argv.extend(["--executable-path", CHROME])
    try:
        code, output = execute([*argv, command, *args], task, environment(task / "home", task.parent / "s"),
                               min(deadline, time.monotonic() + 8))
    except OSError:
        reject("browser_failed")
    if code:
        reject("browser_failed")
    try:
        result = parse_json(output)
    except Rejected:
        reject("invalid_browser_output")
    if not isinstance(result, dict) or result.get("success") is not True or not isinstance(result.get("data"), dict):
        reject("invalid_browser_output")
    field = "snapshot" if command == "snapshot" else args[0] if command == "get" else None
    if field is not None and not isinstance(result["data"].get(field), str):
        reject("invalid_browser_output")
    return result


def artifact(task, name):
    data = read_file(task / "artifacts" / name, MAX_ARTIFACT)
    if not data.startswith(PNG):
        reject("invalid_png")
    return {"name": name, "size": len(data), "sha256": hashlib.sha256(data).hexdigest(),
            "base64": base64.b64encode(data).decode("ascii")}


def request_task(request, options):
    scope = validate(request)
    deadline = time.monotonic() + request.get("timeout_ms", 20000) / 1000
    runtime = runtime_status(options, deadline)
    if not runtime["compatible"]:
        reject("incompatible_browser")
    if not runtime["browser_runtime_available"]:
        reject("browser_runtime_missing")
    root = Path(os.path.abspath(options.task_root))
    private_directory(root)
    # macOS limits Unix socket paths to 103 bytes; private HOME ancestry is longer.
    private_directory(root / "s")
    token = hashlib.sha256(json.dumps([scope[k] for k in ("caller", "run_id", "session_id")]).encode()).hexdigest()
    task = root / token[:24]
    private_directory(task)
    lock = file_open(task / "lock", os.O_RDWR | os.O_CREAT)
    try:
        while True:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    reject("timeout")
                time.sleep(0.02)
        immutable(task / "scope.json", scope, "scope_changed")
        immutable(task / "config.json", CONFIG, "config_changed")
        for name in ("home", "artifacts"):
            private_directory(task / name)
        command, args = request["command"], request["args"]
        closed = task / "closed"
        if closed.exists() or closed.is_symlink():
            cleanup = read_file(closed, 128)
            if command == "close":
                return {"ok": True, "closed": cleanup == b"closed\n",
                        "cleanup": "complete" if cleanup == b"closed\n" else "needs_validation",
                        "session": "t-" + token[:16]}
            reject("session_closed")
        started = task / "started"
        first = not started.exists() and not started.is_symlink()
        if not first:
            read_file(started, 128)
        if first and command != "close" and (command != "open" or args != [scope["initial_url"]]):
            reject("initial_navigation_required")
        def call(cmd, values, until=deadline):
            return browser_call(options.browser, task, scope, token, cmd, values, until)
        def guard():
            current = call("get", ["url"])["data"].get("url")
            in_scope(current, scope)
        def close():
            if not first:
                call("close", [], time.monotonic() + 2)
            write_new(closed, b"closed\n")
        try:
            if command == "close":
                close()
                return {"ok": True, "closed": True, "session": "t-" + token[:16]}
            if not first:
                guard()
            if command == "artifact-read":
                result = {"artifact": artifact(task, args[0])}
            else:
                if first:
                    # Mark ownership before navigation so a failed launch is still cleaned up.
                    write_new(started, b"started\n")
                    first = False
                if command == "screenshot":
                    path = task / "artifacts" / args[0]
                    if path.exists() or path.is_symlink():
                        read_file(path, MAX_ARTIFACT)
                        reject("artifact_exists")
                    # Reserve an owner-only regular file before handing its path to the CLI.
                    write_new(path, b"")
                    args = [str(path)]
                result = {"browser": call("set" if command == "viewport" else command,
                                           ["viewport", *args] if command == "viewport" else args)}
                guard()
                if command == "screenshot":
                    shot = artifact(task, request["args"][0])
                    result["artifact"] = {key: value for key, value in shot.items() if key != "base64"}
            encoded = json.dumps(result.get("browser", {}))
            return {"ok": True, "session": "t-" + token[:16], "untrusted": True,
                    "truncated": len(encoded) >= 24000 or '"truncated": true' in encoded, **result}
        except Rejected as error:
            if str(error) in {"timeout", "output_limit", "browser_failed", "invalid_browser_output", "url_out_of_scope", "invalid_url"}:
                try:
                    close()
                    error.cleanup = "complete"
                except (Rejected, OSError):
                    # The finite daemon idle timeout is the cancellation fallback.
                    if not closed.exists():
                        write_new(closed, b"cleanup_needs_validation\n")
                    error.cleanup = "needs_validation"
            raise
    finally:
        os.close(lock)


def runtime_status(options, deadline):
    code, output = execute([options.browser, "--version"], "/", environment("/nonexistent-agent-browser-task"),
                           min(deadline, time.monotonic() + 3))
    match = re.fullmatch(rb"agent-browser (\d+\.\d+\.\d+)\s*", output)
    version = match[1].decode() if match else None
    compatible = code == 0 and version == "0.39.1"
    runtime = options.browser != BROWSER or os.access(CHROME, os.X_OK)
    return {"ok": compatible and runtime, "version": version, "compatible": compatible,
            "browser_runtime_available": runtime, "browser_launched": False}


def health(options):
    result = runtime_status(options, time.monotonic() + 3)
    print(json.dumps(result))
    return 0 if result["ok"] else 1


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--installed", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--browser", default=BROWSER, help="Source validation executable; disabled in installed wrapper")
    parser.add_argument("--task-root", default=str(ROOT), help="Source validation private root; disabled in installed wrapper")
    try:
        options = parser.parse_args()
        if options.installed and (options.browser != BROWSER or options.task_root != str(ROOT)):
            reject("runtime_override_denied")
        if not os.path.isabs(options.browser):
            reject("invalid_browser_path")
        if options.health:
            return health(options)
        print(json.dumps(request_task(input_request(), options)))
        return 0
    except Rejected as error:
        result = {"ok": False, "error": str(error)}
        if error.cleanup is not None:
            result["cleanup"] = error.cleanup
        print(json.dumps(result))
    except (OSError, ValueError, TypeError):
        print(json.dumps({"ok": False, "error": "runtime_unavailable"}))
    return 1


if __name__ == "__main__":
    sys.exit(main())
