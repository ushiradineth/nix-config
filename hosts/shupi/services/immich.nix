{
  config,
  pkgs,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.immich;
in {
  age.secrets.immich-db-password = {
    file = "${mysecrets}/${hostname}/immich-db-password.age";
    mode = "0400";
  };

  # Create Docker network for Immich containers to communicate
  systemd.services.init-immich-network = {
    description = "Create Docker network for Immich";
    after = ["docker.service" "docker.socket"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${config.virtualisation.docker.package}/bin/docker network inspect immich >/dev/null 2>&1 || \
      ${config.virtualisation.docker.package}/bin/docker network create immich
    '';
  };

  # Ensure containers wait for network to be created
  systemd.services.docker-immich-postgres = {
    after = ["init-immich-network.service"];
    requires = ["init-immich-network.service"];
  };
  systemd.services.docker-immich-redis = {
    after = ["init-immich-network.service"];
    requires = ["init-immich-network.service"];
  };
  systemd.services.docker-immich-server = {
    after = ["init-immich-network.service"];
    requires = ["init-immich-network.service"];
  };
  systemd.services.docker-immich-machine-learning = {
    after = ["init-immich-network.service"];
    requires = ["init-immich-network.service"];
  };

  # Create env files for Immich containers
  system.activationScripts.immich-env = ''
    mkdir -p /var/lib/immich

    # Server env file
    echo "DB_PASSWORD=$(cat ${config.age.secrets.immich-db-password.path})" > /var/lib/immich/server.env
    chmod 600 /var/lib/immich/server.env

    # PostgreSQL env file
    echo "POSTGRES_PASSWORD=$(cat ${config.age.secrets.immich-db-password.path})" > /var/lib/immich/postgres.env
    echo "POSTGRES_USER=postgres" >> /var/lib/immich/postgres.env
    echo "POSTGRES_DB=immich" >> /var/lib/immich/postgres.env
    echo "POSTGRES_INITDB_ARGS=--data-checksums" >> /var/lib/immich/postgres.env
    chmod 600 /var/lib/immich/postgres.env
  '';

  virtualisation.oci-containers.containers.immich-postgres = {
    image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
    autoStart = true;
    volumes = [
      "/srv/immich/postgres:/var/lib/postgresql/data"
    ];
    extraOptions = [
      "--shm-size=128mb"
      "--network=immich"
    ];
    environmentFiles = ["/var/lib/immich/postgres.env"];
    cmd = [
      "postgres"
      "-c"
      "shared_preload_libraries=vchord.so"
      "-c"
      "search_path=\"$user\", public, vchord"
    ];
  };

  virtualisation.oci-containers.containers.immich-redis = {
    image = "docker.io/valkey/valkey:8@sha256:81db6d39e1bba3b3ff32bd3a1b19a6d69690f94a3954ec131277b9a26b95b3aa";
    autoStart = true;
    extraOptions = ["--network=immich"];
  };

  virtualisation.oci-containers.containers.immich-server = {
    image = "ghcr.io/immich-app/immich-server:v2";
    autoStart = true;
    dependsOn = ["immich-redis" "immich-postgres" "immich-machine-learning"];
    volumes = [
      "/srv/immich/library:/data"
      "/etc/localtime:/etc/localtime:ro"
    ];
    ports = ["127.0.0.1:${toString port}:2283"];
    extraOptions = ["--network=immich"];
    environmentFiles = ["/var/lib/immich/server.env"];
    environment = {
      DB_HOSTNAME = "immich-postgres";
      DB_USERNAME = "postgres";
      DB_DATABASE_NAME = "immich";
      REDIS_HOSTNAME = "immich-redis";
      TZ = "UTC";
    };
  };

  virtualisation.oci-containers.containers.immich-machine-learning = {
    image = "ghcr.io/immich-app/immich-machine-learning:v2";
    autoStart = true;
    volumes = [
      "/srv/immich/model-cache:/cache"
    ];
    extraOptions = ["--network=immich"];
    environment = {
      TZ = "UTC";
    };
  };

  # Traefik configuration for reverse proxy
  services.traefik.dynamicConfigOptions.http = {
    services.immich.loadBalancer.servers = [
      {
        url = "http://localhost:${toString port}";
      }
    ];

    routers.immich = {
      rule = "Host(`${config.environment.variables.IMMICH_DOMAIN}`)";
      tls.certResolver = "letsencrypt";
      service = "immich";
      entrypoints = "websecure";
    };
  };

  # Database dump service
  systemd.services.dump-immich-db = {
    description = "Dump Immich PostgreSQL database";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "dump-immich-db" ''
        set -euo pipefail
        BACKUP_DIR="/var/backup/databases"
        mkdir -p "$BACKUP_DIR"

        # Dump to temp file, then atomically replace
        ${config.virtualisation.docker.package}/bin/docker exec immich-postgres \
          pg_dumpall -U postgres > "$BACKUP_DIR/immich.sql.tmp"
        mv "$BACKUP_DIR/immich.sql.tmp" "$BACKUP_DIR/immich.sql"
      '';
      User = "root";
    };
  };

  systemd.timers.dump-immich-db = {
    description = "Timer for Immich database dump";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 01:45:00";
      Persistent = true;
    };
  };
}
