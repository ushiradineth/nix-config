{
  config,
  lib,
  pkgs,
  mylib,
  mysecrets,
  hostname,
  ...
}: let
  port = config.ports.lifeos;
  image = "lifeos:b004a6f";
  origin = "https://${config.environment.variables.LIFEOS_DOMAIN}";
  secret = name: config.age.secrets."lifeos-${name}".path;
  network = name: internal: containers: {
    config = lib.mkMerge [
      (mylib.dockerHelpers.mkDockerNetwork {
        inherit config internal;
        name = "lifeos-${name}";
      })
      (mylib.dockerHelpers.mkContainerNetworkDeps {
        name = "lifeos-${name}";
        inherit containers;
      })
    ];
  };
  common = {
    autoStart = true;
    extraOptions = ["--cap-drop=ALL" "--security-opt=no-new-privileges"];
  };
  route = mylib.traefikHelpers.mkTraefikRoute {
    name = "lifeos";
    domain = config.environment.variables.LIFEOS_DOMAIN;
    inherit port;
  };
in {
  imports = [
    (network "db" true ["lifeos-postgres" "lifeos-web" "lifeos-worker"])
    (network "agent" false ["lifeos-agent" "lifeos-web"])
    (network "finance" false ["lifeos-actual" "lifeos-web"])
    (mylib.dockerHelpers.mkDatabaseDumpService {
      inherit pkgs;
      name = "lifeos";
      description = "Dump LifeOS PostgreSQL into shupi's database backup tier";
      containerDeps = ["lifeos-postgres"];
      dumpCommand = ''
        umask 077
        ${pkgs.docker}/bin/docker exec lifeos-postgres pg_dump -U lifeos -d lifeos -Fc > "$BACKUP_DIR/lifeos.dump.tmp"
        ${pkgs.coreutils}/bin/mv "$BACKUP_DIR/lifeos.dump.tmp" "$BACKUP_DIR/lifeos.dump"
      '';
    })
  ];
  age.secrets =
    lib.genAttrs (map (n: "lifeos-${n}") ["postgres-env" "web-env" "worker-env" "agent-env" "actual-env" "actual-config"]) (name: {
      file = "${mysecrets}/${hostname}/${name}.age";
      mode = "0400";
    })
    // {
      lifeos-wakapi-key = {
        file = "${mysecrets}/${hostname}/lifeos-wakapi-key.age";
        owner = "shu";
        mode = "0400";
      };
      # Read by the unprivileged connector only, mounted separately from its cache.
      lifeos-actual-config = {
        file = "${mysecrets}/${hostname}/lifeos-actual-config.age";
        owner = "shu";
        mode = "0400";
      };
    };
  services.traefik.dynamicConfigOptions.http = lib.recursiveUpdate route {
    routers.lifeos.middlewares = ["lifeos-tailnet-only"];
    # Actual peer address only; forwarded headers never grant access.
    middlewares.lifeos-tailnet-only.ipAllowList.sourceRange = ["100.64.0.0/10" "fd7a:115c:a1e0::/48"];
  };
  systemd.tmpfiles.rules = [
    "d /srv/lifeos 0711 root root -"
    "d /srv/lifeos/postgres 0700 999 999 -"
    "d /srv/lifeos/actual 0700 1000 1000 -"
    "d /srv/lifeos/codex-home 0700 1000 1000 -"
    "d /var/lib/shupi-status 0755 root root -"
    "d /var/lib/lifeos-activity 0755 shu users -"
  ];
  virtualisation.oci-containers.containers = {
    lifeos-postgres = {
      image = "postgres:17-bookworm@sha256:639ab7ceb90e13123085b741fb31ef493fba25463002f6da665352e7b534b652";
      autoStart = true;
      environment = {
        POSTGRES_DB = "lifeos";
        POSTGRES_USER = "lifeos";
      };
      environmentFiles = [(secret "postgres-env")];
      volumes = ["/srv/lifeos/postgres:/var/lib/postgresql/data"];
      extraOptions = ["--network=lifeos-db" "--network-alias=postgres" "--memory=384m" "--health-cmd=pg_isready -U lifeos -d lifeos" "--health-interval=5s" "--health-retries=20"];
    };
    lifeos-web = lib.recursiveUpdate common {
      inherit image;
      dependsOn = ["lifeos-postgres"];
      environment = {
        LIFEOS_ORIGIN = origin;
        CODEX_URL = "http://agent:4313";
        ACTUAL_URL = "http://actual:4314";
      };
      environmentFiles = [(secret "web-env")];
      ports = ["127.0.0.1:${toString port}:3000"];
      volumes = ["/var/lib/shupi-status:/observer:ro" "/var/lib/lifeos-activity:/activity:ro"];
      cmd = ["sh" "-c" "node scripts/migrate.mjs && node .output/server/index.mjs"];
      extraOptions = common.extraOptions ++ ["--network=lifeos-db" "--network=lifeos-agent" "--network=lifeos-finance" "--memory=512m"];
    };
    lifeos-worker = lib.recursiveUpdate common {
      inherit image;
      dependsOn = ["lifeos-postgres"];
      environment = {
        LIFEOS_ORIGIN = origin;
        NTFY_URL = "http://ntfy:80/lifeos";
      };
      environmentFiles = [(secret "worker-env")];
      cmd = ["sh" "-c" "node scripts/migrate.mjs && node scripts/worker.mjs"];
      extraOptions = common.extraOptions ++ ["--network=lifeos-db" "--network=monitoring" "--memory=256m"];
    };
    lifeos-agent = lib.recursiveUpdate common {
      inherit image;
      environmentFiles = [(secret "agent-env")];
      volumes = ["/srv/lifeos/codex-home:/home/node/.codex"];
      cmd = ["node" "scripts/codex-service.mjs"];
      extraOptions = common.extraOptions ++ ["--network=lifeos-agent" "--network-alias=agent" "--memory=512m" "--tmpfs=/workspace:uid=1000,gid=1000,mode=0700" "--tmpfs=/tmp:uid=1000,gid=1000,mode=1777"];
    };
    lifeos-actual = lib.recursiveUpdate common {
      image = "lifeos-actual:bfc5449";
      environment = {ACTUAL_CONFIG_FILE = "/run/secrets/actual-config.json";};
      environmentFiles = [(secret "actual-env")];
      volumes = ["/srv/lifeos/actual:/data" "${secret "actual-config"}:/run/secrets/actual-config.json:ro"];
      extraOptions = common.extraOptions ++ ["--network=lifeos-finance" "--network-alias=actual" "--memory=512m"];
    };
  };
  # Use the same systemd restart-trigger mechanism as other shupi container configuration.
  systemd.services.docker-lifeos-postgres.restartTriggers = [config.age.secrets.lifeos-postgres-env.file];
  systemd.services.docker-lifeos-web.restartTriggers = [config.age.secrets.lifeos-web-env.file];
  systemd.services.docker-lifeos-worker.restartTriggers = [config.age.secrets.lifeos-worker-env.file];
  systemd.services.docker-lifeos-agent.restartTriggers = [config.age.secrets.lifeos-agent-env.file];
  systemd.services.docker-lifeos-actual.restartTriggers = [config.age.secrets.lifeos-actual-env.file config.age.secrets.lifeos-actual-config.file];

  systemd.services.lifeos-activity = {
    description = "Collect read-only LifeOS coding and public commit summaries";
    restartTriggers = [config.age.secrets.lifeos-wakapi-key.file];
    after = ["network-online.target" "wakapi.service"];
    wants = ["network-online.target"];
    environment.WAKAPI_KEY_FILE = secret "wakapi-key";
    serviceConfig = {
      Type = "oneshot";
      User = "shu";
      StateDirectory = "lifeos-activity";
      StateDirectoryMode = "0755";
      ExecStart = "${pkgs.python3}/bin/python /srv/lifeos/app/scripts/collect-activity.py";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      TimeoutStartSec = 90;
      # Root-owned application directory is traversable only for this read-only collector.
      BindReadOnlyPaths = ["/srv/lifeos/app"];
    };
  };
  systemd.timers.lifeos-activity = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "15min";
    };
  };
}
