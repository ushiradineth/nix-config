{
  pkgs,
  config,
  mysecrets,
  hostname,
  myvars,
  ...
}: let
  repository = "sftp://shu@shupi//srv/backups/shu-code";
  tailscale = "/opt/homebrew/bin/tailscale";
  restic = "${pkgs.restic}/bin/restic";
  jq = "${pkgs.jq}/bin/jq";
  python = "${pkgs.python3}/bin/python3";
  maxAgeHours = 24;

  # Backup script: checks if backup is needed (24+ hours old) and runs if so
  backupScript = pkgs.writeShellScript "restic-backup-code" ''
    set -euo pipefail

    TAILSCALE="${tailscale}"
    RESTIC="${restic}"
    JQ="${jq}"
    PYTHON="${python}"
    STATE_FILE="/tmp/restic-backup-tailscale-state"
    LOG_FILE="/tmp/restic-backup-code.log"
    PASSWORD_FILE="${config.age.secrets.restic-password.path}"
    REPOSITORY="${repository}"
    MAX_AGE_HOURS=${toString maxAgeHours}
    SSH_IDENTITY="/Users/shu/.ssh/shu"

    log() {
      echo "[$(date)] $1" | tee -a "$LOG_FILE"
    }

    restic_cmd() {
      $RESTIC \
        -o "sftp.command=ssh -i $SSH_IDENTITY -o IdentitiesOnly=yes -o BatchMode=yes shu@shupi -s sftp" \
        "$@"
    }

    cleanup() {
      if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "connected_by_us" ]; then
        log "Disconnecting Tailscale (we connected it for backup)..."
        $TAILSCALE down || true
      fi
      rm -f "$STATE_FILE"
    }
    trap cleanup EXIT

    # Ensure Tailscale is connected
    if $TAILSCALE status &>/dev/null; then
      echo "already_connected" > "$STATE_FILE"
    else
      log "Tailscale not connected, connecting..."
      if $TAILSCALE up &>/dev/null; then
        echo "connected_by_us" > "$STATE_FILE"
      else
        log "Failed to connect Tailscale, skipping backup check"
        exit 0
      fi
    fi

    # Check if shupi is reachable via SSH
    if ! ssh -i "$SSH_IDENTITY" -o IdentitiesOnly=yes -o ConnectTimeout=5 -o BatchMode=yes shu@shupi true &>/dev/null; then
      log "shupi not reachable via SSH, skipping backup check"
      exit 0
    fi

    # Check if backup is needed (24+ hours since last snapshot)
    LATEST_SNAPSHOT=$(restic_cmd -r "$REPOSITORY" --password-file "$PASSWORD_FILE" snapshots --latest 1 --json 2>/dev/null | $JQ -r '.[0].time // empty')

    if [ -n "$LATEST_SNAPSHOT" ]; then
      # Calculate age in hours
      SNAPSHOT_EPOCH=$($PYTHON -c 'from datetime import datetime; import sys; print(int(datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00")).timestamp()))' "$LATEST_SNAPSHOT" 2>/dev/null || echo "0")
      CURRENT_EPOCH=$(date "+%s")
      AGE_HOURS=$(( (CURRENT_EPOCH - SNAPSHOT_EPOCH) / 3600 ))

      if [ "$AGE_HOURS" -lt "$MAX_AGE_HOURS" ]; then
        log "Last backup is ''${AGE_HOURS}h old (< ''${MAX_AGE_HOURS}h), no backup needed"
        exit 0
      fi
      log "Last backup is ''${AGE_HOURS}h old (>= ''${MAX_AGE_HOURS}h), starting backup..."
    else
      log "No snapshots found, starting backup..."
    fi

    # Run backup
    log "=== Backup started ==="

    # Initialize repository if needed (ignore error if already initialized)
    restic_cmd -r "$REPOSITORY" --password-file "$PASSWORD_FILE" init 2>/dev/null || true

    restic_cmd -r "$REPOSITORY" --password-file "$PASSWORD_FILE" backup \
      /Users/shu/Code \
      --tag=shu-code \
      --tag=macos \
      --tag=automated \
      --exclude="**/node_modules" \
      --exclude="**/.next" \
      --exclude="**/dist" \
      --exclude="**/build" \
      --exclude="**/out" \
      --exclude="**/.output" \
      --exclude="**/.nuxt" \
      --exclude="**/.cache" \
      --exclude="**/.git" \
      --exclude="**/.svn" \
      --exclude="**/__pycache__" \
      --exclude="**/target" \
      --exclude="**/venv" \
      --exclude="**/.venv" \
      --exclude="**/env" \
      --exclude="**/.env" \
      --exclude="**/vendor" \
      --exclude="**/pkg" \
      --exclude="**/.idea" \
      --exclude="**/.vscode" \
      --exclude="**/.DS_Store" \
      --exclude="**/thumbs.db" \
      --exclude="**/tmp" \
      --exclude="**/temp" \
      --exclude="**/*.log" \
      --exclude="**/*.tmp" \
      2>&1 | tee -a "$LOG_FILE"

    # Clear stale locks before prune/forget
    restic_cmd -r "$REPOSITORY" --password-file "$PASSWORD_FILE" unlock \
      2>&1 | tee -a "$LOG_FILE" || true

    # Prune old snapshots
    restic_cmd -r "$REPOSITORY" --password-file "$PASSWORD_FILE" forget \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 3 \
      --tag=shu-code \
      --prune \
      2>&1 | tee -a "$LOG_FILE"

    log "=== Backup completed ==="
  '';
in {
  age.secrets.restic-password = {
    file = "${mysecrets}/${hostname}/restic-password.age";
    owner = myvars.username;
    mode = "0400";
  };

  environment.systemPackages = [pkgs.restic];

  home-manager.users.${myvars.username}.home.file."Library/LaunchAgents/com.restic.backup-code.plist".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>com.restic.backup-code</string>
      <key>ProgramArguments</key>
      <array>
        <string>/bin/bash</string>
        <string>${backupScript}</string>
      </array>
      <key>StartInterval</key>
      <integer>7200</integer>
      <key>StandardOutPath</key>
      <string>/tmp/restic-backup-code-stdout.log</string>
      <key>StandardErrorPath</key>
      <string>/tmp/restic-backup-code-stderr.log</string>
      <key>RunAtLoad</key>
      <true/>
    </dict>
    </plist>
  '';

  system.activationScripts.remove-system-restic-backup-code-agent.text = ''
    if [ -e /Library/LaunchAgents/com.restic.backup-code.plist ]; then
      /bin/launchctl bootout gui/$(id -u ${myvars.username}) /Library/LaunchAgents/com.restic.backup-code.plist >/dev/null 2>&1 || true
      rm -f /Library/LaunchAgents/com.restic.backup-code.plist
    fi
  '';

  system.activationScripts.load-user-restic-backup-code-agent.text = ''
    agent=/Users/${myvars.username}/Library/LaunchAgents/com.restic.backup-code.plist
    if [ -e "$agent" ]; then
      /bin/launchctl bootout gui/$(id -u ${myvars.username}) "$agent" >/dev/null 2>&1 || true
      /bin/launchctl bootstrap gui/$(id -u ${myvars.username}) "$agent" >/dev/null 2>&1 || true
    fi
  '';
  # Notifications handled by shupi backup staleness monitor
}
