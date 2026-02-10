{lib}: {
  mkDockerNetwork = {
    config,
    name,
    networkName ? name,
  }: {
    systemd.services."init-${name}-network" = {
      description = "Create Docker network for ${name}";
      after = ["docker.service" "docker.socket"];
      requires = ["docker.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${config.virtualisation.docker.package}/bin/docker network inspect ${networkName} >/dev/null 2>&1 || \
        ${config.virtualisation.docker.package}/bin/docker network create ${networkName}
      '';
    };
  };

  mkContainerNetworkDeps = {
    name,
    containers,
  }: {
    systemd.services =
      lib.genAttrs
      (map (container: "docker-${container}") containers)
      (_: {
        after = ["init-${name}-network.service"];
        requires = ["init-${name}-network.service"];
      });
  };

  mkDatabaseDumpService = {
    pkgs,
    name,
    description,
    dumpCommand,
    backupDir ? "/var/backup/databases",
    onCalendar ? "*-*-* 01:45:00",
    containerDeps ? [],
    ...
  }: {
    systemd.services."dump-${name}-db" = {
      inherit description;
      after = map (c: "docker-${c}.service") containerDeps;
      requires = map (c: "docker-${c}.service") containerDeps;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "dump-${name}-db" ''
          set -euo pipefail
          BACKUP_DIR="${backupDir}"
          mkdir -p "$BACKUP_DIR"

          ${dumpCommand}
        '';
        User = "root";
      };
    };

    systemd.timers."dump-${name}-db" = {
      description = "Timer for ${name} database dump";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = onCalendar;
        Persistent = true;
      };
    };
  };
}
