{
  pkgs,
  myvars,
  mysecrets,
  hostname,
  config,
  ...
}: let
  port = 4096;
  username = "opencode";
  resolveTailscale = ''
    TS_BIN="$(command -v tailscale || true)"
    if [ -z "$TS_BIN" ] && [ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]; then
      TS_BIN=/Applications/Tailscale.app/Contents/MacOS/Tailscale
    fi

    if [ -z "$TS_BIN" ]; then
      printf 'tailscale binary not found in PATH or app bundle\n' >&2
      false
    fi
  '';
  runOpenCodeWeb = pkgs.writeShellScript "opencode-web" ''
    set -euo pipefail

    export PATH="/opt/homebrew/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${myvars.username}/bin:$HOME/.local/share/pnpm:$PATH"

    PASSWORD_FILE="${config.age.secrets.opencode-web-password.path}"
    PASSWORD=$(tr -d '\r\n' < "$PASSWORD_FILE")

    if [ -z "$PASSWORD" ]; then
      echo "opencode-web password is empty" >&2
      exit 1
    fi

    if ! command -v opencode >/dev/null 2>&1; then
      echo "opencode binary not found in PATH: $PATH" >&2
      exit 1
    fi

    export OPENCODE_SERVER_USERNAME="${username}"
    export OPENCODE_SERVER_PASSWORD="$PASSWORD"

    exec "$(command -v opencode)" web --hostname 127.0.0.1 --port ${toString port}
  '';
in {
  environment.shellAliases = {
    start_oc_web = ''
      launchctl bootstrap gui/$(id -u) /Library/LaunchAgents/ai.opencode.web.plist >/dev/null 2>&1 || true
      launchctl kickstart -k gui/$(id -u)/ai.opencode.web
      ${resolveTailscale}
      "$TS_BIN" serve --bg --https=443 http://127.0.0.1:${toString port}
    '';
    stop_oc_web = ''
      ${resolveTailscale}
      "$TS_BIN" serve reset >/dev/null 2>&1 || true
      launchctl bootout gui/$(id -u)/ai.opencode.web >/dev/null 2>&1 || launchctl stop gui/$(id -u)/ai.opencode.web
    '';
    oc_web_url = ''
      ${resolveTailscale}
      "$TS_BIN" serve status
    '';
  };

  age.secrets.opencode-web-password = {
    file = "${mysecrets}/${hostname}/opencode-web-password.age";
    owner = myvars.username;
    mode = "0400";
  };

  launchd.agents.opencode-web = {
    serviceConfig = {
      Label = "ai.opencode.web";
      ProgramArguments = ["${runOpenCodeWeb}"];
      KeepAlive = false;
      RunAtLoad = false;
      ProcessType = "Background";
      WorkingDirectory = "/Users/${myvars.username}";
      StandardOutPath = "/tmp/opencode-web-stdout.log";
      StandardErrorPath = "/tmp/opencode-web-stderr.log";
    };
  };
}
