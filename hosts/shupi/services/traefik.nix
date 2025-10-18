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
          storage = "/srv/traefik/acme.json";
          caServer = "https://acme-v02.api.letsencrypt.org/directory";

          dnsChallenge = {
            provider = "cloudflare";
            delayBeforeCheck = 0;
            resolvers = ["1.1.1.1:53" "8.8.8.8:53"];
          };
        };
      };

      providers.docker = {
        endpoint = "unix:///var/run/docker.sock";
        exposedByDefault = false;
        watch = true;
      };

      api = {
        dashboard = true;
        insecure = false;
      };

      log = {
        level = "INFO";
      };

      accessLog = {};
    };
  };

  age.secrets.traefik-cf-api-key.file = "${mysecrets}/${hostname}/traefik-cf-api-key.age";
  environment.variables.CLOUDFLARE_DNS_API_TOKEN = "${config.age.secrets.traefik-cf-api-key.path}";

  networking.firewall.allowedTCPPorts = [80 443];

  users.users.traefik.extraGroups = ["docker"];
}
