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
        tls = {
          certResolver = "letsencrypt";
        };
        service = "api@internal";
        entrypoints = "websecure";
      };
    };
  };

  age.secrets.traefik-cf-api-key.file = "${mysecrets}/${hostname}/traefik-cf-api-key.age";
  environment.variables.CLOUDFLARE_DNS_API_TOKEN = "${config.age.secrets.traefik-cf-api-key.path}";

  networking.firewall.allowedTCPPorts = [80 443];
}
