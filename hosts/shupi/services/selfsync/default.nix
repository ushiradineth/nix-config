{
  config,
  lib,
  mylib,
  pkgs,
  ...
}: let
  port = config.ports.selfsync;
  domain = config.environment.variables.SELFSYNC_DOMAIN;
  docker = "${config.virtualisation.docker.package}/bin/docker";
  binary = "/usr/local/bin/selfsync";
  route = mylib.traefikHelpers.mkTraefikRoute {
    name = "selfsync";
    host = "127.0.0.1";
    inherit domain port;
  };
in {
  # /srv belongs to shu on this host, so tmpfiles refuses its ownership transition.
  # Prepare bind mounts before Docker can create them as root.
  systemd.services.docker-selfsync.preStart = lib.mkBefore ''
    ${pkgs.coreutils}/bin/install -d -m 0700 -o root -g root /srv/selfsync
    ${pkgs.coreutils}/bin/install -d -m 0700 -o 65532 -g 65532 /srv/selfsync/data /srv/selfsync/backups
  '';

  virtualisation.oci-containers.containers.selfsync = {
    image = "ghcr.io/darkildo/selfsync:0.10.1@sha256:7087832c865663353d19af517b5a00c1988a413ecd84036f0d32a02626b52a71";
    user = "65532:65532";
    ports = ["127.0.0.1:${toString port}:8085"];
    volumes = [
      "/srv/selfsync/data:/data"
      "/srv/selfsync/backups:/backups"
    ];
    environment = {
      SELFSYNC_PUBLIC_URL = "https://${domain}";
      SELFSYNC_TRUSTED_PROXY = "1";
      SELFSYNC_LOG = "info";
    };
    extraOptions = [
      "--read-only"
      "--tmpfs=/tmp:rw,noexec,nosuid,size=64m"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges:true"
      "--memory=256m"
    ];
  };

  services.traefik.dynamicConfigOptions.http = lib.recursiveUpdate route {
    middlewares.selfsync-tailnet.ipAllowList.sourceRange = ["100.64.0.0/10" "fd7a:115c:a1e0::/48"];
    routers.selfsync.middlewares = ["selfsync-tailnet"];
  };

  systemd.services.selfsync-backup = {
    description = "Take a consistent Selfsync snapshot before offsite backup";
    requires = ["docker-selfsync.service"];
    after = ["docker-selfsync.service"];
    onFailure = ["notify-backup-failure@selfsync.service"];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
      ExecStart = "${docker} exec selfsync ${binary} backup --rotate /backups --keep 7 --copy";
    };
  };
  # Never send a live SQLite database to Restic. Snapshot failure fails the job.
  systemd.services.restic-backups-app-data = {
    requires = ["selfsync-backup.service"];
    after = ["selfsync-backup.service"];
  };
  services.restic.backups.app-data.paths = ["/srv/selfsync/backups"];

  systemd.services.selfsync-verify = {
    description = "Verify Selfsync databases and blob hashes";
    requires = ["docker-selfsync.service"];
    after = ["docker-selfsync.service"];
    onFailure = ["notify-backup-failure@selfsync-verify.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${docker} exec selfsync ${binary} verify";
    };
  };
  systemd.timers.selfsync-verify = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Sun *-*-* 01:00:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };
}
