{
  config,
  hostname,
  lib,
  mysecrets,
  ...
}: let
  domains = lib.filterAttrs (name: domain:
    name
    != "EMAIL_DOMAIN"
    && lib.hasSuffix "_DOMAIN" name
    && (domain == "shupi.ushira.com" || lib.hasSuffix ".shupi.ushira.com" domain))
  config.environment.variables;
  shortUrls = lib.mapAttrs' (_: domain:
    lib.nameValuePair
    (
      if domain == "shupi.ushira.com"
      then "home"
      else lib.removeSuffix ".shupi.ushira.com" domain
    )
    domain)
  domains;
in {
  services.adguardhome.settings.filtering.rewrites =
    lib.mapAttrsToList (alias: _: {
      domain = "${alias}.shu";
      answer = "100.74.32.50";
      enabled = true;
    })
    shortUrls;

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
            # Let the HTTP-only shortcuts redirect before the HTTPS catch-all.
            priority = 1;
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
            delayBeforeCheck = 10;
            resolvers = ["10.64.0.1:53"]; # Mullvad DNS - public DNS blocked by VPN
            disablePropagationCheck = true; # Skip direct NS query (blocked by Mullvad)
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
      http.routers =
        (lib.mapAttrs' (alias: _:
          lib.nameValuePair "short-url-${alias}" {
            rule = "Host(`${alias}.shu`)";
            entryPoints = ["web"];
            priority = 100;
            middlewares = ["short-url-${alias}"];
            service = "noop@internal";
          })
        shortUrls)
        // {
          api = {
            rule = "Host(`${config.environment.variables.TRAEFIK_DOMAIN}`)";
            tls.certResolver = "letsencrypt";
            service = "api@internal";
            entrypoints = "websecure";
          };
        };
      http.middlewares = lib.mapAttrs' (alias: domain:
        lib.nameValuePair "short-url-${alias}" {
          redirectRegex = {
            regex = "^http://[^/]+/(.*)";
            replacement = "https://${domain}/\${1}";
            permanent = false;
          };
        })
      shortUrls;
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

            # Create env file with Cloudflare credentials
            cat > /var/lib/traefik/env <<EOF
      CLOUDFLARE_DNS_API_TOKEN=$(cat ${config.age.secrets.traefik-cf-api-key.path})
      CF_ZONE_ID=53b488f1366aa53788c00136298784b7
      EOF
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
