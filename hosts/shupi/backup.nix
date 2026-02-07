{
  config,
  pkgs,
  hostname,
  mysecrets,
  ...
}: let
  hetznerUser = config.environment.variables.HETZNER_USER;
  hetznerHost = config.environment.variables.HETZNER_HOST;
  repoBase = "sftp://${hetznerUser}@${hetznerHost}:23/backups/shupi";
in {
  environment.systemPackages = with pkgs; [
    restic
  ];

  # Age secrets
  age.secrets.hetzner-password = {
    file = "${mysecrets}/${hostname}/hetzner-password.age";
    mode = "0400";
  };

  age.secrets.restic-password = {
    file = "${mysecrets}/${hostname}/restic-password.age";
    mode = "0400";
  };

  programs.ssh.knownHosts = {
    "u522887.your-storagebox.de".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
  };

  # Backup directory for database dumps (created by individual service dump scripts)
  # Directory for macOS host (shu) code backups (not backed up to Hetzner)
  systemd.tmpfiles.rules = [
    "d /var/backup/databases 0755 root root -"
    "d /srv/backups/shu-code 0755 root root -"
  ];

  # Notification service templates for backup success/failure
  # Uses localhost HTTP to ntfy container (no auth needed internally)
  systemd.services."notify-backup-success@" = {
    description = "Notify backup success for %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.curl}/bin/curl -H 'Title: Backup Success: %i' -H 'Priority: default' -H 'Tags: backup' -d 'Backup job %i completed successfully' http://127.0.0.1:${toString config.ports.ntfy}/alerts";
    };
  };

  systemd.services."notify-backup-failure@" = {
    description = "Notify backup failure for %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.curl}/bin/curl -H 'Title: Backup Failed: %i' -H 'Priority: urgent' -H 'Tags: backup,failure' -d 'Backup job %i FAILED. Check journalctl for details.' http://127.0.0.1:${toString config.ports.ntfy}/alerts";
    };
  };

  # Increase timeout for restic backup services (SFTP connections can be slow to close)
  # Add notification hooks for backup success/failure
  systemd.services = {
    "restic-backups-critical-data" = {
      serviceConfig.TimeoutStopSec = "5min";
      onSuccess = ["notify-backup-success@critical-data.service"];
      onFailure = ["notify-backup-failure@critical-data.service"];
    };
    "restic-backups-app-data" = {
      serviceConfig.TimeoutStopSec = "5min";
      onSuccess = ["notify-backup-success@app-data.service"];
      onFailure = ["notify-backup-failure@app-data.service"];
    };
    "restic-backups-config" = {
      serviceConfig.TimeoutStopSec = "5min";
      onSuccess = ["notify-backup-success@config.service"];
      onFailure = ["notify-backup-failure@config.service"];
    };
    "restic-backups-db-dumps" = {
      serviceConfig.TimeoutStopSec = "5min";
      onSuccess = ["notify-backup-success@db-dumps.service"];
      onFailure = ["notify-backup-failure@db-dumps.service"];
    };
  };

  # Monitor for stale macOS backup (shu -> shupi)
  # Alerts if no backup received within 48 hours
  systemd.services.check-shu-backup-staleness = {
    description = "Check if macOS backup is stale";
    path = with pkgs; [findutils curl coreutils];
    serviceConfig.Type = "oneshot";
    script = ''
      BACKUP_DIR="/srv/backups/shu-code"
      MAX_AGE_HOURS=48

      # Check if any file was modified within MAX_AGE_HOURS
      RECENT=$(find "$BACKUP_DIR" -type f -mmin -$((MAX_AGE_HOURS * 60)) 2>/dev/null | head -1)

      if [ -z "$RECENT" ]; then
        curl -H "Title: macOS Backup Stale" \
          -H "Priority: high" \
          -H "Tags: backup,macos,warning" \
          -d "No macOS backup received in the last $MAX_AGE_HOURS hours" \
          http://127.0.0.1:${toString config.ports.ntfy}/alerts
      fi
    '';
  };

  systemd.timers.check-shu-backup-staleness = {
    description = "Timer for macOS backup staleness check";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 06:00:00"; # Run daily at 6 AM
      Persistent = true;
    };
  };

  # Restic backup jobs
  services.restic.backups = {
    # TIER 1: Critical Data (photos, files) - 2:00 AM
    critical-data = {
      initialize = true;
      repository = "${repoBase}/critical-data";
      passwordFile = config.age.secrets.restic-password.path;

      paths = [
        "/srv/immich/library"
        "/srv/seafile/data"
      ];

      extraOptions = [
        "sftp.command='${pkgs.sshpass}/bin/sshpass -f ${config.age.secrets.hetzner-password.path} -- ssh -4 ${hetznerHost} -l ${hetznerUser} -s sftp'"
      ];

      extraBackupArgs = [
        "--tag=critical-data"
        "--tag=shupi"
        "--tag=automated"
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--tag=critical-data"
      ];

      timerConfig = {
        OnCalendar = "*-*-* 02:00:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # TIER 2: Application Data - 2:30 AM
    app-data = {
      initialize = true;
      repository = "${repoBase}/app-data";
      passwordFile = config.age.secrets.restic-password.path;

      paths = [
        "/srv/actualbudget"
        "/srv/umami"
        "/srv/uptimekuma"
        "/srv/portainer"
        "/srv/couchdb/data" # CouchDB uses file-based backup (no SQL dump)
        "/srv/infisical/redis" # Redis has no SQL dump alternative
        "/srv/forgejo/data"
        "/srv/forgejo/repos"
        "/srv/forgejo/git"
      ];

      extraOptions = [
        "sftp.command='${pkgs.sshpass}/bin/sshpass -f ${config.age.secrets.hetzner-password.path} -- ssh -4 ${hetznerHost} -l ${hetznerUser} -s sftp'"
      ];

      extraBackupArgs = [
        "--tag=app-data"
        "--tag=shupi"
        "--tag=automated"
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 8"
        "--keep-monthly 12"
        "--tag=app-data"
      ];

      timerConfig = {
        OnCalendar = "*-*-* 02:30:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # TIER 3: Configuration Files - 3:00 AM
    config = {
      initialize = true;
      repository = "${repoBase}/config";
      passwordFile = config.age.secrets.restic-password.path;

      paths = [
        "/srv/adguard"
        "/srv/traefik"
        "/srv/wakapi"
        "/srv/couchdb/config"
        "/srv/ntfy"
        "/srv/alertmanager"
      ];

      extraOptions = [
        "sftp.command='${pkgs.sshpass}/bin/sshpass -f ${config.age.secrets.hetzner-password.path} -- ssh -4 ${hetznerHost} -l ${hetznerUser} -s sftp'"
      ];

      extraBackupArgs = [
        "--tag=config"
        "--tag=shupi"
        "--tag=automated"
      ];

      pruneOpts = [
        "--keep-daily 30"
        "--keep-monthly 12"
        "--tag=config"
      ];

      timerConfig = {
        OnCalendar = "*-*-* 03:00:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # TIER 4: Database Dumps - 2:15 AM
    # Note: Individual services create their own dump scripts/timers at 1:45 AM
    # This tier just backs up the /var/backup/databases directory
    db-dumps = {
      initialize = true;
      repository = "${repoBase}/db-dumps";
      passwordFile = config.age.secrets.restic-password.path;

      paths = [
        "/var/backup/databases"
      ];

      extraOptions = [
        "sftp.command='${pkgs.sshpass}/bin/sshpass -f ${config.age.secrets.hetzner-password.path} -- ssh -4 ${hetznerHost} -l ${hetznerUser} -s sftp'"
      ];

      extraBackupArgs = [
        "--tag=db-dumps"
        "--tag=shupi"
        "--tag=automated"
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-monthly 6"
        "--tag=db-dumps"
      ];

      timerConfig = {
        OnCalendar = "*-*-* 02:15:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
