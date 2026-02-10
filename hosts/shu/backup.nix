{pkgs, ...}: let
  passwordFile = "/Users/shu/.config/restic/password";
  repository = "sftp://shu@shupi//srv/backups/shu-code";
  tailscale = "/opt/homebrew/bin/tailscale";
  restic = "${pkgs.restic}/bin/restic";
  jq = "${pkgs.jq}/bin/jq";
  maxAgeHours = 24;

  # Backup script: checks if backup is needed (24+ hours old) and runs if so
  backupScript = pkgs.writeShellScript "restic-backup-code" ''
    set -euo pipefail

    TAILSCALE="${tailscale}"
    RESTIC="${restic}"
    JQ="${jq}"
    STATE_FILE="/tmp/restic-backup-tailscale-state"
    LOG_FILE="/tmp/restic-backup-code.log"
    PASSWORD_FILE="${passwordFile}"
    REPOSITORY="${repository}"
    MAX_AGE_HOURS=${toString maxAgeHours}

    log() {
      echo "[$(date)] $1" | tee -a "$LOG_FILE"
    }

    cleanup() {
      if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "we_connected" ]; then
        log "Disconnecting Tailscale (we connected it for backup)..."
        $TAILSCALE down || true
      fi
      rm -f "$STATE_FILE"
    }
    trap cleanup EXIT

    # Check if Tailscale is connected
    if $TAILSCALE status &>/dev/null; then
      echo "already_connected" > "$STATE_FILE"
    else
      log "Tailscale not connected, skipping backup check"
      exit 0
    fi

    # Check if shupi is reachable via SSH
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes shu@shupi true &>/dev/null; then
      log "shupi not reachable via SSH, skipping backup check"
      exit 0
    fi

    # Check if backup is needed (24+ hours since last snapshot)
    LATEST_SNAPSHOT=$($RESTIC -r "$REPOSITORY" --password-file "$PASSWORD_FILE" snapshots --latest 1 --json 2>/dev/null | $JQ -r '.[0].time // empty')

    if [ -n "$LATEST_SNAPSHOT" ]; then
      # Calculate age in hours
      SNAPSHOT_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$(echo "$LATEST_SNAPSHOT" | cut -d. -f1)" "+%s" 2>/dev/null || echo "0")
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
    $RESTIC -r "$REPOSITORY" --password-file "$PASSWORD_FILE" init 2>/dev/null || true

    $RESTIC -r "$REPOSITORY" --password-file "$PASSWORD_FILE" backup \
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

    # Prune old snapshots
    $RESTIC -r "$REPOSITORY" --password-file "$PASSWORD_FILE" forget \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 3 \
      --tag=shu-code \
      --prune \
      2>&1 | tee -a "$LOG_FILE"

    log "=== Backup completed ==="
  '';
in {
  environment.systemPackages = [pkgs.restic];

  # Run every 2 hours, backup only if last snapshot is 24+ hours old
  launchd.agents.restic-backup-code = {
    serviceConfig = {
      Label = "com.restic.backup-code";
      ProgramArguments = ["${backupScript}"];
      StartInterval = 7200; # Every 2 hours
      StandardOutPath = "/tmp/restic-backup-code-stdout.log";
      StandardErrorPath = "/tmp/restic-backup-code-stderr.log";
      RunAtLoad = true; # Check on login
    };
  };
  # Notifications handled by shupi backup staleness monitor
}
