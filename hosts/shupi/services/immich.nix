{
  config,
  pkgs,
  lib,
  mylib,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.immich;
in
  lib.mkMerge [
    {
      age.secrets.immich-db-password = {
        file = "${mysecrets}/${hostname}/immich-db-password.age";
        mode = "0400";
      };

      system.activationScripts.immich-env = ''
        mkdir -p /var/lib/immich

        echo "DB_PASSWORD=$(cat ${config.age.secrets.immich-db-password.path})" > /var/lib/immich/server.env
        chmod 600 /var/lib/immich/server.env

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
        image = "ghcr.io/immich-app/immich-server:v2.4.1";
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
    }
    (mylib.dockerHelpers.mkDockerNetwork {
      config = config;
      name = "immich";
    })
    (mylib.dockerHelpers.mkContainerNetworkDeps {
      name = "immich";
      containers = [
        "immich-postgres"
        "immich-redis"
        "immich-server"
        "immich-machine-learning"
      ];
    })
    {
      services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
        name = "immich";
        domain = config.environment.variables.IMMICH_DOMAIN;
        port = port;
      };
    }
    (mylib.dockerHelpers.mkDatabaseDumpService {
      config = config;
      pkgs = pkgs;
      name = "immich";
      description = "Dump Immich PostgreSQL database";
      dumpCommand = ''
        ${config.virtualisation.docker.package}/bin/docker exec immich-postgres \
          pg_dumpall -U postgres > "$BACKUP_DIR/immich.sql.tmp"
        mv "$BACKUP_DIR/immich.sql.tmp" "$BACKUP_DIR/immich.sql"
      '';
    })
  ]
