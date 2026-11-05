{
  config,
  lib,
  pkgs,
  mylib,
  ...
}: let
  port = config.ports.affine;
  domain = config.environment.variables.AFFINE_DOMAIN;
  docker = "${config.virtualisation.docker.package}/bin/docker";
  image = "ghcr.io/toeverything/affine:0.27.4@sha256:adb3cea3eb4a50a6116dbab7dc045252b54ede3e73828a85a58daf78da3b1f6d";
  route = mylib.traefikHelpers.mkTraefikRoute {
    name = "affine";
    host = "127.0.0.1";
    inherit domain port;
  };
in
  lib.mkMerge [
    {
      systemd.tmpfiles.rules = [
        "d /srv/affine 0700 root root -"
        "d /srv/affine/storage 0700 root root -"
        "d /srv/affine/config 0700 root root -"
        "d /var/lib/affine 0700 root root -"
      ];

      systemd.services.affine-credentials = {
        description = "Initialize persistent AFFiNE database credentials";
        before = ["docker-affine-postgres.service" "docker-affine.service"];
        requiredBy = ["docker-affine-postgres.service" "docker-affine.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          UMask = "0077";
          StateDirectory = "affine";
          StateDirectoryMode = "0700";
        };
        script = ''
          set -euo pipefail
          if [ ! -s /var/lib/affine/database-password ]; then
            ${pkgs.openssl}/bin/openssl rand -hex 32 > /var/lib/affine/database-password
          fi
          password="$(</var/lib/affine/database-password)"
          printf 'POSTGRES_PASSWORD=%s\n' "$password" > /var/lib/affine/postgres.env.tmp
          mv /var/lib/affine/postgres.env.tmp /var/lib/affine/postgres.env
          printf 'DATABASE_URL=postgresql://affine:%s@affine-postgres:5432/affine\n' "$password" > /var/lib/affine/server.env.tmp
          mv /var/lib/affine/server.env.tmp /var/lib/affine/server.env
        '';
      };

      virtualisation.oci-containers.containers = {
        affine-postgres = {
          image = "docker.io/pgvector/pgvector:pg16@sha256:a45475a5bc7882f19e9ca17d49b67f665fa04d500350de2c47af325662445aec";
          volumes = ["/srv/affine/postgres:/var/lib/postgresql/data"];
          environmentFiles = ["/var/lib/affine/postgres.env"];
          environment = {
            POSTGRES_USER = "affine";
            POSTGRES_DB = "affine";
            POSTGRES_INITDB_ARGS = "--data-checksums";
          };
          extraOptions = [
            "--network=affine"
            "--memory=384m"
            "--health-cmd=pg_isready -h 127.0.0.1 -U affine -d affine"
            "--health-interval=10s"
            "--health-timeout=5s"
            "--health-retries=12"
          ];
        };
        affine-redis = {
          image = "docker.io/library/redis:7-alpine@sha256:c1945f0eeb2d503f8421952da953a3804d38e4f004d4ef11d57826da59d2c332";
          cmd = ["redis-server" "--maxmemory" "64mb" "--maxmemory-policy" "noeviction"];
          extraOptions = [
            "--network=affine"
            "--memory=128m"
            "--health-cmd=redis-cli ping"
            "--health-interval=10s"
            "--health-timeout=5s"
            "--health-retries=12"
          ];
        };
        affine = {
          inherit image;
          dependsOn = ["affine-postgres" "affine-redis"];
          ports = ["127.0.0.1:${toString port}:3010"];
          volumes = [
            "/srv/affine/storage:/root/.affine/storage"
            "/srv/affine/config:/root/.affine/config"
          ];
          environmentFiles = ["/var/lib/affine/server.env"];
          environment = {
            REDIS_SERVER_HOST = "affine-redis";
            AFFINE_INDEXER_ENABLED = "false";
            AFFINE_SERVER_EXTERNAL_URL = "https://${domain}";
            NODE_OPTIONS = "--max-old-space-size=768";
          };
          extraOptions = [
            "--network=affine"
            "--memory=1280m"
            "--health-cmd=node -e \"fetch('http://127.0.0.1:3010/info').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))\""
            "--health-interval=30s"
            "--health-timeout=10s"
            "--health-start-period=90s"
            "--health-retries=5"
          ];
        };
      };

      systemd.services.docker-affine.preStart = lib.mkAfter ''
        for attempt in $(seq 1 60); do
          if ${docker} exec affine-postgres pg_isready -h 127.0.0.1 -U affine -d affine &&
             ${docker} exec affine-redis redis-cli ping; then
            break
          fi
          sleep 2
        done
        ${docker} exec affine-postgres pg_isready -h 127.0.0.1 -U affine -d affine
        ${docker} exec affine-redis redis-cli ping
        ${docker} run --rm --network=affine --memory=1024m \
          --env-file /var/lib/affine/server.env \
          -e REDIS_SERVER_HOST=affine-redis -e AFFINE_INDEXER_ENABLED=false \
          -e NODE_OPTIONS=--max-old-space-size=768 \
          -v /srv/affine/storage:/root/.affine/storage \
          -v /srv/affine/config:/root/.affine/config \
          ${image} node ./scripts/self-host-predeploy.js
      '';
      systemd.services.docker-affine.serviceConfig.TimeoutStartSec = lib.mkForce "15min";
      systemd.services.docker-affine.serviceConfig.RestartSec = "30s";
      systemd.services.docker-affine-postgres.serviceConfig.RestartSec = "30s";
      systemd.services.docker-affine-redis.serviceConfig.RestartSec = "30s";

      services.traefik.dynamicConfigOptions.http = lib.recursiveUpdate route {
        middlewares.affine-tailnet.ipAllowList.sourceRange = ["100.64.0.0/10" "fd7a:115c:a1e0::/48"];
        routers.affine.middlewares = ["affine-tailnet"];
      };
    }
    (mylib.dockerHelpers.mkDockerNetwork {
      inherit config;
      name = "affine";
    })
    (mylib.dockerHelpers.mkContainerNetworkDeps {
      name = "affine";
      containers = ["affine" "affine-postgres" "affine-redis"];
    })
    (mylib.dockerHelpers.mkDatabaseDumpService {
      inherit config pkgs;
      name = "affine";
      description = "Dump AFFiNE PostgreSQL database";
      containerDeps = ["affine-postgres"];
      dumpCommand = ''
        umask 077
        ${docker} exec affine-postgres pg_dumpall -U affine > "$BACKUP_DIR/affine.sql.tmp"
        mv "$BACKUP_DIR/affine.sql.tmp" "$BACKUP_DIR/affine.sql"
      '';
    })
  ]
