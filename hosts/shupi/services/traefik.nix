{
  config,
  hostname,
  mysecrets,
  ...
}: {
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
            permanent = true;
          };
        };
        websecure = {
          address = ":443";
          http.tls.certResolver = "letsencrypt";
        };
      };

      certificatesResolvers.letsencrypt = {
        acme = {
          email = config.environment.variables.ACME_EMAIL;
          storage = "/srv/traefik/data/acme.json";
          caServer = "https://acme-v02.api.letsencrypt.org/directory";

          dnsChallenge = {
            provider = "cloudflare";
            delayBeforeCheck = 0;
            resolvers = ["1.1.1.1:53" "8.8.8.8:53"];
          };
        };
      };

      api = {
        dashboard = true;
      };

      log = {
        level = "WARN";
      };

      accessLog = {};
    };

    dynamicConfigOptions = {
      http.routers.api = {
        rule = "Host(`${config.environment.variables.TRAEFIK_DOMAIN}`)";
        tls.certResolver = "letsencrypt";
        service = "api@internal";
        entrypoints = "websecure";
      };
    };
  };

  age.secrets.traefik-cf-api-key.file = "${mysecrets}/${hostname}/traefik-cf-api-key.age";

  system.activationScripts.traefikSetup = {
    text = ''
      echo "Setting up Traefik directories and permissions..."
      mkdir -p /srv/traefik/data
      mkdir -p /var/lib/traefik

      # Ensure traefik owns its directories
      chown -R traefik:traefik /srv/traefik
      chmod 700 /srv/traefik/data

      # Create env file
      echo "CLOUDFLARE_DNS_API_TOKEN=$(cat ${config.age.secrets.traefik-cf-api-key.path})" > /var/lib/traefik/env
      chmod 600 /var/lib/traefik/env
    '';
    deps = [];
  };

  systemd.services.traefik.serviceConfig = {
    EnvironmentFile = ["/var/lib/traefik/env"];
    ReadWritePaths = ["/srv/traefik"];
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
