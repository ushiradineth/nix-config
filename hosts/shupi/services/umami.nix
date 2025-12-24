{
  config,
  pkgs,
  lib,
  mylib,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.umami;
in
  lib.mkMerge [
    {
      age.secrets.umami-db-password = {
        file = "${mysecrets}/${hostname}/umami-db-password.age";
        mode = "0400";
      };

      age.secrets.umami-app-secret = {
        file = "${mysecrets}/${hostname}/umami-app-secret.age";
        mode = "0400";
      };

      system.activationScripts.umami-env = ''
        mkdir -p /var/lib/umami

        DB_PASSWORD=$(cat ${config.age.secrets.umami-db-password.path})
        APP_SECRET=$(cat ${config.age.secrets.umami-app-secret.path})

        echo "POSTGRES_DB=umami" > /var/lib/umami/postgres.env
        echo "POSTGRES_USER=umami" >> /var/lib/umami/postgres.env
        echo "POSTGRES_PASSWORD=$DB_PASSWORD" >> /var/lib/umami/postgres.env
        chmod 600 /var/lib/umami/postgres.env

        echo "DATABASE_URL=postgresql://umami:$DB_PASSWORD@umami-db:5432/umami" > /var/lib/umami/app.env
        echo "DATABASE_TYPE=postgresql" >> /var/lib/umami/app.env
        echo "APP_SECRET=$APP_SECRET" >> /var/lib/umami/app.env
        echo "DISABLE_TELEMETRY=1" >> /var/lib/umami/app.env
        chmod 600 /var/lib/umami/app.env
      '';

      virtualisation.oci-containers.containers.umami-db = {
        image = "postgres:15-alpine";
        autoStart = true;
        volumes = [
          "/srv/umami/db:/var/lib/postgresql/data"
        ];
        extraOptions = [
          "--network=umami"
          "--health-cmd=pg_isready -U umami"
          "--health-interval=10s"
          "--health-start-period=30s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
        environmentFiles = ["/var/lib/umami/postgres.env"];
      };

      virtualisation.oci-containers.containers.umami-app = {
        image = "ghcr.io/umami-software/umami:postgresql-latest";
        autoStart = true;
        dependsOn = ["umami-db"];
        ports = ["127.0.0.1:${toString port}:3000"];
        extraOptions = ["--network=umami"];
        environmentFiles = ["/var/lib/umami/app.env"];
      };
    }
    (mylib.dockerHelpers.mkDockerNetwork {
      config = config;
      name = "umami";
    })
    (mylib.dockerHelpers.mkContainerNetworkDeps {
      name = "umami";
      containers = ["umami-db" "umami-app"];
    })
    (mylib.dockerHelpers.mkDatabaseDumpService {
      config = config;
      pkgs = pkgs;
      name = "umami";
      description = "Dump Umami PostgreSQL database";
      dumpCommand = ''
        # Dump to temp file, then atomically replace
        ${config.virtualisation.docker.package}/bin/docker exec umami-db \
          pg_dumpall -U umami > "$BACKUP_DIR/umami.sql.tmp"
        mv "$BACKUP_DIR/umami.sql.tmp" "$BACKUP_DIR/umami.sql"
      '';
    })
  ]
