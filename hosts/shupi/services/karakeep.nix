{
  config,
  mylib,
  pkgs,
  ...
}: let
  port = config.ports.karakeep;
  domain = config.environment.variables.KARAKEEP_DOMAIN;
  environmentFile = "/srv/karakeep/karakeep.env";
in {
  imports = [
    (mylib.dockerHelpers.mkDockerNetwork {
      inherit config;
      name = "karakeep";
    })
    (mylib.dockerHelpers.mkContainerNetworkDeps {
      name = "karakeep";
      containers = ["karakeep" "karakeep-chrome" "karakeep-meilisearch"];
    })
  ];

  systemd.tmpfiles.rules = [
    "d /srv/karakeep 0700 root root -"
    "d /srv/karakeep/data 0755 root root -"
    "d /srv/karakeep/meilisearch 0755 root root -"
  ];

  system.activationScripts.karakeep-env = ''
    (
      set -e
      ${pkgs.coreutils}/bin/install -d -m 0700 /srv/karakeep
      if [ ! -s ${environmentFile} ]; then
        umask 077
        envFile=$(${pkgs.coreutils}/bin/mktemp /srv/karakeep/.env.XXXXXX)
        trap 'rm -f "$envFile"' EXIT
        {
          printf 'NEXTAUTH_SECRET=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 32)"
          printf 'MEILI_MASTER_KEY=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 32)"
        } > "$envFile"
        mv "$envFile" ${environmentFile}
      fi
    )
  '';

  virtualisation.oci-containers.containers = {
    karakeep = {
      image = "ghcr.io/karakeep-app/karakeep:0.33.2@sha256:6a35e9caccb26ac4e1ba47341326f3a59d8cfbc6508e7ca0011189847dd1836a";
      autoStart = true;
      dependsOn = ["karakeep-chrome" "karakeep-meilisearch"];
      ports = ["127.0.0.1:${toString port}:3000"];
      volumes = ["/srv/karakeep/data:/data"];
      environmentFiles = [environmentFile];
      environment = {
        DATA_DIR = "/data";
        NEXTAUTH_URL = "https://${domain}";
        MEILI_ADDR = "http://karakeep-meilisearch:7700";
        BROWSER_WEB_URL = "http://karakeep-chrome:9222";
      };
      extraOptions = [
        "--network=karakeep"
        "--health-start-period=60s"
      ];
    };

    karakeep-chrome = {
      image = "ghcr.io/karakeep-app/karakeep-chrome:release@sha256:a9c98fc5b5af11d52bb0c9825c0d961e43409e3db579edc828d3617a20224f0d";
      autoStart = true;
      cmd = [
        "--disable-gpu"
        "--disable-dev-shm-usage"
        "--hide-scrollbars"
        "--disable-blink-features=AutomationControlled"
        "--window-size=1440,900"
      ];
      extraOptions = ["--network=karakeep" "--init"];
    };

    karakeep-meilisearch = {
      image = "getmeili/meilisearch:v1.41.0@sha256:dfd6c3cf3b27d53f849f242567f33f68dbd2f715e8859166f69e921486da1208";
      autoStart = true;
      volumes = ["/srv/karakeep/meilisearch:/meili_data"];
      environmentFiles = [environmentFile];
      environment = {
        MEILI_NO_ANALYTICS = "true";
        MEILI_ENV = "production";
      };
      extraOptions = ["--network=karakeep"];
    };
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "karakeep";
    host = "127.0.0.1";
    inherit domain port;
  };
}
