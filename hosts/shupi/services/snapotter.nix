{
  config,
  hostname,
  lib,
  mylib,
  mysecrets,
  pkgs,
  ...
}: let
  port = config.ports.snapotter;
  domain = config.environment.variables.SNAPOTTER_DOMAIN;
  appEnv = "/var/lib/snapotter/app.env";
  postgresEnv = "/var/lib/snapotter/postgres.env";
  redisEnv = "/var/lib/snapotter/redis.env";
  appSettings = ''
    AUTH_ENABLED=true
    DEFAULT_USERNAME=admin
    DEFAULT_PASSWORD_FILE=/run/secrets/snapotter-admin-password
    COOKIE_SECRET_FILE=/run/secrets/snapotter-cookie-secret
    SKIP_MUST_CHANGE_PASSWORD=false
    DB_STARTUP_TIMEOUT_MS=60000
    SNAPOTTER_TELEMETRY=0
    TRUST_PROXY=loopback,linklocal,uniquelocal
    CONCURRENT_JOBS=1
    MAX_WORKER_THREADS=2
    MAX_BATCH_SIZE=5
    MAX_UPLOAD_SIZE_MB=100
    MAX_MEGAPIXELS=50
    MAX_VIDEO_DURATION_S=300
    PROCESSING_TIMEOUT_S=600
  '';
  environmentVersion = pkgs.writeText "snapotter-environment-version" ''
    ${appSettings}
    POSTGRES_USER=snapotter
    POSTGRES_DB=snapotter
    REDIS_MAXMEMORY=256mb
  '';
  route = mylib.traefikHelpers.mkTraefikRoute {
    name = "snapotter";
    host = "127.0.0.1";
    inherit domain port;
  };
in
  lib.mkMerge [
    {
      age.secrets =
        lib.genAttrs [
          "snapotter-db-password"
          "snapotter-redis-password"
          "snapotter-admin-password"
          "snapotter-cookie-secret"
        ] (name: {
          file = "${mysecrets}/${hostname}/${name}.age";
          mode = "0400";
        });

      systemd.tmpfiles.rules = [
        "d /var/lib/snapotter 0700 root root -"
        "d /srv/snapotter 0711 root root -"
        "d /srv/snapotter/data 0700 999 999 -"
        "d /srv/snapotter/workspace 0700 999 999 -"
        "d /srv/snapotter/postgres 0700 70 70 -"
        "d /srv/snapotter/redis 0700 999 999 -"
      ];

      system.activationScripts.snapotter-env = ''
        set -euo pipefail
        umask 0077
        ${pkgs.coreutils}/bin/install -d -m 0700 /var/lib/snapotter

        DB_PASSWORD="$(${pkgs.coreutils}/bin/tr -d '\n' < ${config.age.secrets.snapotter-db-password.path})"
        REDIS_PASSWORD="$(${pkgs.coreutils}/bin/tr -d '\n' < ${config.age.secrets.snapotter-redis-password.path})"

        app_tmp="$(${pkgs.coreutils}/bin/mktemp /var/lib/snapotter/app.env.XXXXXX)"
        postgres_tmp="$(${pkgs.coreutils}/bin/mktemp /var/lib/snapotter/postgres.env.XXXXXX)"
        redis_tmp="$(${pkgs.coreutils}/bin/mktemp /var/lib/snapotter/redis.env.XXXXXX)"
        trap '${pkgs.coreutils}/bin/rm -f "$app_tmp" "$postgres_tmp" "$redis_tmp"' EXIT

        ${pkgs.coreutils}/bin/cat > "$app_tmp" <<EOF
        ${appSettings}
        DATABASE_URL=postgres://snapotter:$DB_PASSWORD@snapotter-postgres:5432/snapotter
        REDIS_URL=redis://:$REDIS_PASSWORD@snapotter-redis:6379
        EOF

        ${pkgs.coreutils}/bin/cat > "$postgres_tmp" <<EOF
        POSTGRES_USER=snapotter
        POSTGRES_PASSWORD=$DB_PASSWORD
        POSTGRES_DB=snapotter
        EOF

        ${pkgs.coreutils}/bin/cat > "$redis_tmp" <<EOF
        REDIS_PASSWORD=$REDIS_PASSWORD
        EOF

        ${pkgs.coreutils}/bin/chmod 0600 "$app_tmp" "$postgres_tmp" "$redis_tmp"
        ${pkgs.coreutils}/bin/mv -f "$app_tmp" ${appEnv}
        ${pkgs.coreutils}/bin/mv -f "$postgres_tmp" ${postgresEnv}
        ${pkgs.coreutils}/bin/mv -f "$redis_tmp" ${redisEnv}
        trap - EXIT
      '';

      virtualisation.oci-containers.containers = {
        snapotter-postgres = {
          image = "postgres:17-alpine@sha256:742f40ea20b9ff2ff31db5458d127452988a2164df9e17441e191f3b72252193";
          autoStart = true;
          log-driver = "json-file";
          volumes = ["/srv/snapotter/postgres:/var/lib/postgresql/data"];
          environmentFiles = [postgresEnv];
          extraOptions = [
            "--network=snapotter"
            "--network-alias=snapotter-postgres"
            "--cpus=1"
            "--memory=512m"
            "--memory-swap=512m"
            "--pids-limit=256"
            "--cap-drop=ALL"
            "--cap-add=CHOWN"
            "--cap-add=DAC_OVERRIDE"
            "--cap-add=FOWNER"
            "--cap-add=SETGID"
            "--cap-add=SETUID"
            "--security-opt=no-new-privileges:true"
            "--health-cmd=pg_isready -U snapotter -d snapotter"
            "--health-interval=10s"
            "--health-timeout=5s"
            "--health-retries=12"
            "--health-start-period=15s"
            "--log-opt=max-size=10m"
            "--log-opt=max-file=3"
          ];
        };

        snapotter-redis = {
          image = "redis:8-alpine@sha256:9d317178eceac8454a2284a9e6df2466b93c745529947f0cd42a0fa9609d7005";
          autoStart = true;
          log-driver = "json-file";
          volumes = ["/srv/snapotter/redis:/data"];
          environmentFiles = [redisEnv];
          cmd = [
            "sh"
            "-c"
            ''exec redis-server --maxmemory-policy noeviction --maxmemory 256mb --appendonly yes --requirepass "$REDIS_PASSWORD"''
          ];
          extraOptions = [
            "--network=snapotter"
            "--network-alias=snapotter-redis"
            "--cpus=0.5"
            "--memory=384m"
            "--memory-swap=384m"
            "--pids-limit=256"
            "--cap-drop=ALL"
            "--cap-add=CHOWN"
            "--cap-add=DAC_OVERRIDE"
            "--cap-add=FOWNER"
            "--cap-add=SETGID"
            "--cap-add=SETUID"
            "--security-opt=no-new-privileges:true"
            ''--health-cmd=redis-cli -a "$REDIS_PASSWORD" --no-auth-warning ping | grep -q PONG''
            "--health-interval=10s"
            "--health-timeout=5s"
            "--health-retries=12"
            "--health-start-period=10s"
            "--log-opt=max-size=10m"
            "--log-opt=max-file=3"
          ];
        };

        snapotter = {
          image = "ghcr.io/snapotter-hq/snapotter:2.2.0@sha256:2e11b4fa9138fa93e0fdfde5da3a2d042eebcfa81dd51286488872a3eb8086c8";
          autoStart = true;
          log-driver = "json-file";
          dependsOn = ["snapotter-postgres" "snapotter-redis"];
          ports = ["127.0.0.1:${toString port}:1349"];
          volumes = [
            "/srv/snapotter/data:/data"
            "/srv/snapotter/workspace:/tmp/workspace"
            "${config.age.secrets.snapotter-admin-password.path}:/run/secrets/snapotter-admin-password:ro"
            "${config.age.secrets.snapotter-cookie-secret.path}:/run/secrets/snapotter-cookie-secret:ro"
          ];
          environmentFiles = [appEnv];
          extraOptions = [
            "--network=snapotter"
            "--cpus=2"
            "--memory=2g"
            "--memory-swap=2g"
            "--pids-limit=512"
            "--shm-size=256m"
            "--cap-drop=ALL"
            "--cap-add=CHOWN"
            "--cap-add=SETUID"
            "--cap-add=SETGID"
            "--cap-add=DAC_OVERRIDE"
            "--cap-add=FOWNER"
            "--cap-add=KILL"
            "--security-opt=no-new-privileges:true"
            "--health-cmd=curl -sf --max-time 5 http://localhost:1349/api/v1/health"
            "--health-interval=30s"
            "--health-timeout=5s"
            "--health-retries=3"
            "--health-start-period=60s"
            "--log-opt=max-size=50m"
            "--log-opt=max-file=5"
          ];
        };
      };

      systemd.services = {
        docker-snapotter-postgres.restartTriggers = [
          config.age.secrets.snapotter-db-password.file
          environmentVersion
        ];
        docker-snapotter-redis.restartTriggers = [
          config.age.secrets.snapotter-redis-password.file
          environmentVersion
        ];
        docker-snapotter.restartTriggers = [
          config.age.secrets.snapotter-db-password.file
          config.age.secrets.snapotter-redis-password.file
          config.age.secrets.snapotter-admin-password.file
          config.age.secrets.snapotter-cookie-secret.file
          environmentVersion
        ];
      };
    }

    (mylib.dockerHelpers.mkDockerNetwork {
      inherit config;
      name = "snapotter";
    })

    (mylib.dockerHelpers.mkContainerNetworkDeps {
      name = "snapotter";
      containers = ["snapotter-postgres" "snapotter-redis" "snapotter"];
    })

    {
      services.traefik.dynamicConfigOptions.http = lib.recursiveUpdate route {
        middlewares = {
          snapotter-tailnet-only.ipAllowList.sourceRange = [
            "100.64.0.0/10"
            "fd7a:115c:a1e0::/48"
          ];
          snapotter-body.buffering.maxRequestBodyBytes = 104857600;
        };
        routers.snapotter.middlewares = [
          "snapotter-tailnet-only"
          "snapotter-body"
        ];
      };
    }

    (mylib.dockerHelpers.mkDatabaseDumpService {
      inherit config pkgs;
      name = "snapotter";
      description = "Dump SnapOtter PostgreSQL database";
      containerDeps = ["snapotter-postgres"];
      dumpCommand = ''
        ${config.virtualisation.docker.package}/bin/docker exec snapotter-postgres \
          pg_dump --format=custom --no-owner -U snapotter snapotter > "$BACKUP_DIR/snapotter.dump.tmp"
        test -s "$BACKUP_DIR/snapotter.dump.tmp"
        ${config.virtualisation.docker.package}/bin/docker exec -i snapotter-postgres \
          pg_restore --list < "$BACKUP_DIR/snapotter.dump.tmp" >/dev/null
        ${pkgs.coreutils}/bin/mv -f "$BACKUP_DIR/snapotter.dump.tmp" "$BACKUP_DIR/snapotter.dump"
      '';
    })
  ]
