{pkgs, ...}: let
  # Backup script for restic to shupi over Tailscale
  backupScript = pkgs.writeShellScript "restic-backup-code" ''
    set -euo pipefail

    TAILSCALE="/opt/homebrew/bin/tailscale"
    RESTIC="${pkgs.restic}/bin/restic"
    STATE_FILE="/tmp/restic-backup-tailscale-state"
    LOG_FILE="/tmp/restic-backup-code.log"
    PASSWORD_FILE="/Users/shu/.config/restic/password"
    REPOSITORY="sftp://shu@shupi:/srv/backups/shu-code"

    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "=== Backup started at $(date) ==="

    cleanup() {
      if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "we_connected" ]; then
        echo "Disconnecting Tailscale (we connected it for backup)..."
        $TAILSCALE down || true
      else
        echo "Leaving Tailscale connected (was already connected)"
      fi
      rm -f "$STATE_FILE"
    }
    trap cleanup EXIT

    # Ensure Tailscale is connected
    if $TAILSCALE status &>/dev/null; then
      echo "already_connected" > "$STATE_FILE"
      echo "Tailscale already connected"
    else
      echo "we_connected" > "$STATE_FILE"
      echo "Tailscale not running, attempting to connect..."
      $TAILSCALE up --reset

      # Wait for connection (max 30 seconds)
      for i in {1..30}; do
        if $TAILSCALE status &>/dev/null; then
          echo "Tailscale connected"
          break
        fi
        sleep 1
      done
    fi

    # Verify shupi is reachable via SSH (what restic will use)
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes shu@shupi true &>/dev/null; then
      echo "ERROR: Cannot reach shupi via SSH"
      exit 1
    fi

    echo "Tailscale connected, shupi reachable. Starting backup..."

    # Initialize repository if needed (ignore error if already initialized)
    $RESTIC -r "$REPOSITORY" --password-file "$PASSWORD_FILE" init 2>/dev/null || true

    # Run backup
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
      --exclude="**/*.tmp"

    # Prune old snapshots
    $RESTIC -r "$REPOSITORY" --password-file "$PASSWORD_FILE" forget \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 3 \
      --tag=shu-code \
      --prune

    echo "=== Backup completed at $(date) ==="
  '';
in {
  # Install restic
  environment.systemPackages = [pkgs.restic];

  # Launchd agent for daily backup
  launchd.agents.restic-backup-code = {
    serviceConfig = {
      Label = "com.restic.backup-code";
      ProgramArguments = ["${backupScript}"];
      StartCalendarInterval = [
        {
          Hour = 2;
          Minute = 0;
        }
      ];
      StandardOutPath = "/tmp/restic-backup-code-stdout.log";
      StandardErrorPath = "/tmp/restic-backup-code-stderr.log";
      RunAtLoad = false;
    };
  };
  # Notifications handled by shupi backup staleness monitor
}
