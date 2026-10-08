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
  cshuModrinthHost = "cshuu.modrinth.gg";
  cshuModrinthBackupDir = "/var/backup/minecraft/cshu";
  cshuModrinthServerDir = "/var/backup/minecraft/cshu-server";
  pullCshuModrinthBackups = pkgs.writeShellApplication {
    name = "pull-cshu-modrinth-backups";
    runtimeInputs = [pkgs.rclone];
    text = ''
      credential="$(<${config.age.secrets.cshu-modrinth-sftp.path})"
      username="''${credential%%:*}"
      password="''${credential#*:}"

      if [[ -z "$username" || -z "$password" || "$password" == "$credential" ]]; then
        echo "Invalid cshu Modrinth SFTP credential format" >&2
        exit 1
      fi

      export RCLONE_CONFIG_MODRINTH_TYPE=sftp
      export RCLONE_CONFIG_MODRINTH_HOST=${cshuModrinthHost}
      export RCLONE_CONFIG_MODRINTH_USER="$username"
      export RCLONE_CONFIG_MODRINTH_PORT=2222
      export RCLONE_CONFIG_MODRINTH_SHELL_TYPE=none
      export RCLONE_CONFIG_MODRINTH_DISABLE_HASHCHECK=true
      export RCLONE_CONFIG_MODRINTH_KNOWN_HOSTS_FILE=/etc/ssh/ssh_known_hosts
      RCLONE_CONFIG_MODRINTH_PASS="$(rclone obscure "$password")"
      export RCLONE_CONFIG_MODRINTH_PASS
      unset credential password

      rclone sync \
        modrinth:simplebackups \
        ${cshuModrinthBackupDir} \
        --config /dev/null \
        --immutable \
        --min-age 10m \
        --check-first \
        --delete-after \
        --max-delete 30 \
        --transfers 1 \
        --checkers 2 \
        --multi-thread-streams 0 \
        --timeout 2m \
        --log-level INFO

      rclone sync \
        modrinth: \
        ${cshuModrinthServerDir} \
        --config /dev/null \
        --include '/mods/**' \
        --include '/config/**' \
        --include '/defaultconfigs/**' \
        --include '/configureddefaults/**' \
        --include '/server.properties' \
        --include '/user_jvm_args.txt' \
        --include '/ops.json' \
        --include '/whitelist.json' \
        --include '/banned-ips.json' \
        --include '/banned-players.json' \
        --include '/server-icon.png' \
        --exclude '*' \
        --check-first \
        --delete-after \
        --max-delete 50 \
        --transfers 1 \
        --checkers 2 \
        --multi-thread-streams 0 \
        --timeout 2m \
        --log-level INFO
    '';
  };
in {
  environment.systemPackages = with pkgs; [
    rclone
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

  age.secrets.cshu-modrinth-sftp = {
    file = "${mysecrets}/${hostname}/cshu-modrinth-sftp.age";
    mode = "0400";
  };

  programs.ssh.knownHosts = {
    "u522887.your-storagebox.de".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
    "cshu-modrinth" = {
      hostNames = ["[${cshuModrinthHost}]:2222"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL4xJqeIWv/mXoFBOne4H2UxZ0iQEuoc8OvK/5acHBzD";
    };
  };

  # Backup directory for database dumps (created by individual service dump scripts)
  # Directory for macOS host (shu) code backups (not backed up to Hetzner)
  systemd.tmpfiles.rules = [
    "d /var/backup/databases 0755 root root -"
    "d ${cshuModrinthBackupDir} 0700 root root -"
    "d ${cshuModrinthServerDir} 0700 root root -"
    "d /srv/backups/shu-code 0755 root root -"
  ];

  # Notification service template for backup failures
  # Uses localhost HTTP to ntfy container (no auth needed internally)
  systemd.services."notify-backup-failure@" = {
    description = "Notify backup failure for %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.curl}/bin/curl -H 'Title: Backup Failed: %i' -H 'Priority: urgent' -H 'Tags: backup,failure' -d 'Backup job %i FAILED. Check journalctl for details.' http://127.0.0.1:${toString config.ports.ntfy}/alerts";
    };
  };

  # Increase timeout for restic backup services (SFTP connections can be slow to close)
  # Add notification hooks for backup failures
  systemd.services = {
    "restic-backups-critical-data" = {
      serviceConfig.TimeoutStopSec = "5min";
      serviceConfig.RuntimeMaxSec = "12h";
      onFailure = ["notify-backup-failure@critical-data.service"];
    };
    "restic-backups-app-data" = {
      serviceConfig.TimeoutStopSec = "5min";
      serviceConfig.RuntimeMaxSec = "12h";
      onFailure = ["notify-backup-failure@app-data.service"];
    };
    "restic-backups-config" = {
      serviceConfig.TimeoutStopSec = "5min";
      serviceConfig.RuntimeMaxSec = "12h";
      onFailure = ["notify-backup-failure@config.service"];
    };
    "restic-backups-db-dumps" = {
      serviceConfig.TimeoutStopSec = "5min";
      serviceConfig.RuntimeMaxSec = "12h";
      onFailure = ["notify-backup-failure@db-dumps.service"];
    };
    "restic-backups-minecraft-cshu" = {
      serviceConfig = {
        ExecStartPre = "${pullCshuModrinthBackups}/bin/pull-cshu-modrinth-backups";
        TimeoutStartSec = "12h";
        TimeoutStopSec = "5min";
      };
      onFailure = ["notify-backup-failure@minecraft-cshu.service"];
    };
  };

  # Restic backup jobs
  services.restic.backups = {
    # TIER 1: Critical Data (photos, files) - 2:00 AM
    critical-data = {
      initialize = false;
      repository = "${repoBase}/critical-data";
      passwordFile = config.age.secrets.restic-password.path;

      paths = [
        "/srv/immich/library"
        "/srv/seafile/data"
        "/srv/snapotter/data"
      ];

      extraOptions = [
        "sftp.command='${pkgs.sshpass}/bin/sshpass -f ${config.age.secrets.hetzner-password.path} -- ssh -4 ${hetznerHost} -l ${hetznerUser} -s sftp'"
      ];

      extraBackupArgs = [
        "--tag=critical-data"
        "--tag=shupi"
        "--tag=automated"
        "--exclude=/srv/seafile/data/logs"
        "--exclude=/srv/seafile/data/seafile/logs"
        "--exclude=/srv/seafile/data/seafile/seafile-data/httptemp"
        "--exclude=/srv/seafile/data/seafile/seafile-data/tmpfiles"
        "--exclude=/srv/seafile/data/seafile/seahub-data/thumbnail"
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
      initialize = false;
      repository = "${repoBase}/app-data";
      passwordFile = config.age.secrets.restic-password.path;

      paths = [
        "/srv/lifeos/actual"
        "/srv/lifeos/codex-home"
        "/srv/actualbudget"
        "/srv/umami"
        "/srv/uptimekuma"
        "/srv/portainer"
        "/srv/couchdb/data" # CouchDB uses file-based backup (no SQL dump)
        "/srv/infisical/redis" # Redis has no SQL dump alternative
        "/srv/forgejo/data"
        "/srv/forgejo/repos"
        "/srv/forgejo/git"
        "/srv/linkding"
        "/srv/backrest/config"
        "/srv/backrest/data"
        "/srv/paperclip"
        "/srv/snapotter/redis"
        "/srv/google-mcp"
      ];

      extraOptions = [
        "sftp.command='${pkgs.sshpass}/bin/sshpass -f ${config.age.secrets.hetzner-password.path} -- ssh -4 ${hetznerHost} -l ${hetznerUser} -s sftp'"
      ];

      extraBackupArgs = [
        "--tag=app-data"
        "--tag=shupi"
        "--tag=automated"
        "--exclude=/srv/paperclip/instances/default/db"
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
      initialize = false;
      repository = "${repoBase}/config";
      passwordFile = config.age.secrets.restic-password.path;

      paths = [
        "/srv/adguard"
        "/srv/traefik"
        "/srv/wakapi"
        "/srv/couchdb/config"
        "/srv/ntfy"
        "/srv/alertmanager"
        "/var/lib/paperclip"
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
      initialize = false;
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

    # Minecraft Simple Backups pulled from Modrinth - 4:00 AM
    minecraft-cshu = {
      initialize = true;
      repository = "${repoBase}/minecraft-cshu";
      passwordFile = config.age.secrets.restic-password.path;

      paths = [
        cshuModrinthBackupDir
        cshuModrinthServerDir
      ];

      extraOptions = [
        "sftp.command='${pkgs.sshpass}/bin/sshpass -f ${config.age.secrets.hetzner-password.path} -- ssh -4 ${hetznerHost} -l ${hetznerUser} -s sftp'"
      ];

      extraBackupArgs = [
        "--tag=minecraft-cshu"
        "--tag=shupi"
        "--tag=automated"
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 8"
        "--keep-monthly 12"
        "--tag=minecraft-cshu"
      ];

      timerConfig = {
        OnCalendar = "*-*-* 04:00:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
