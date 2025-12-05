{config, ...}: let
  port = config.ports.homepage;
in {
  services.homepage-dashboard = {
    enable = true;
    listenPort = port;

    environmentFile = builtins.toFile "homepage-env" ''
      HOMEPAGE_ALLOWED_HOSTS=${config.environment.variables.HOMEPAGE_DOMAIN}
    '';

    settings = {
      title = "shupi";
      theme = "dark";
      color = "slate";
      headerStyle = "boxed";
      hideErrors = false;
      showStats = true;
      statusStyle = "dot";
      layout = {
        "Infrastructure" = {
          style = "row";
          columns = 4;
        };
        "Network & Security" = {
          style = "row";
          columns = 3;
        };
        "Applications" = {
          style = "row";
          columns = 3;
        };
        "Development" = {
          style = "row";
          columns = 2;
        };
        "Quick Links" = {
          style = "row";
          columns = 4;
        };
      };
      quicklaunch = {
        searchDescriptions = true;
        hideInternetSearch = false;
      };
      favicon = "https://ushira.com/favicon.svg";
      cardBlur = "lg";
      background = {
        image = "https://sf.shupi.ushira.com/seafhttp/f/60de3dc0de714ec7b8d7/?op=view";
        blur = "md";
        saturate = "50";
        brightness = "50";
        opacity = "50";
      };
    };

    services = [
      {
        "Infrastructure" = [
          {
            Traefik = {
              icon = "traefik.png";
              href = "https://${config.environment.variables.TRAEFIK_DOMAIN}";
              description = "Reverse Proxy Dashboard";
            };
          }
          {
            Portainer = {
              icon = "portainer.png";
              href = "https://${config.environment.variables.PORTAINER_DOMAIN}";
              description = "Docker Management";
            };
          }
          {
            "Uptime Kuma" = {
              icon = "uptime-kuma.png";
              href = "https://${config.environment.variables.UPTIMEKUMA_DOMAIN}";
              description = "Service Monitoring";
            };
          }
          {
            Grafana = {
              icon = "grafana.png";
              href = "https://${config.environment.variables.GRAFANA_DOMAIN}";
              description = "Metrics Dashboard";
            };
          }
        ];
      }
      {
        "Network & Security" = [
          {
            AdGuard = {
              icon = "adguard-home.png";
              href = "https://${config.environment.variables.ADGUARD_DOMAIN}";
              description = "DNS & Adblocking";
            };
          }
          {
            Tailscale = {
              icon = "tailscale.png";
              href = "https://login.tailscale.com/";
              description = "Tailscale Dashboard";
            };
          }
          {
            Cloudflared = {
              icon = "cloudflare.png";
              href = "https://dash.cloudflare.com/";
              description = "Cloudflare Dashboard";
            };
          }
        ];
      }
      {
        "Applications" = [
          {
            "Actual Budget" = {
              icon = "https://avatars.githubusercontent.com/u/37879538?v=4";
              href = "https://${config.environment.variables.ACTUALBUDGET_DOMAIN}";
              description = "Budget Management";
            };
          }
          {
            Seafile = {
              icon = "https://manual.seafile.com/latest/media/seafile-transparent-1024.png";
              href = "https://${config.environment.variables.SEAFILE_DOMAIN}";
              description = "Cloud Storage";
            };
          }
          {
            Immich = {
              icon = "https://avatars.githubusercontent.com/u/109746326?v=4";
              href = "https://${config.environment.variables.IMMICH_DOMAIN}";
              description = "Photo Management";
            };
          }
          {
            Umami = {
              icon = "https://avatars.githubusercontent.com/u/105618662?s=200&v=4";
              href = "https://${config.environment.variables.UMAMI_DOMAIN}";
              description = "Privacy-focused Analytics";
            };
          }
        ];
      }
      {
        "Development" = [
          {
            Wakapi = {
              icon = "https://avatars.githubusercontent.com/u/82216526?s=200&v=4";
              href = "https://${config.environment.variables.WAKAPI_DOMAIN}";
              description = "Coding Time Tracking";
            };
          }
        ];
      }
    ];

    bookmarks = [
      {
        Entertainment = [
          {
            YouTube = [
              {
                icon = "youtube.png";
                abbr = "YT";
                href = "https://youtube.com/";
              }
            ];
          }
          {
            "X (Twitter)" = [
              {
                icon = "twitter.png";
                abbr = "X";
                href = "https://twitter.com/x";
              }
            ];
          }
          {
            "ushira.com" = [
              {
                icon = "https://ushira.com/favicon.svg";
                abbr = "ushira.com";
                href = "https://ushira.com";
              }
            ];
          }
          {
            GitHub = [
              {
                icon = "github.png";
                abbr = "GitHub";
                href = "https://github.com/ushiradineth";
              }
            ];
          }
        ];
      }
      {
        Nix = [
          {
            MyNixOS = [
              {
                icon = "https://mynixos.com/icon.svg";
                href = "https://mynixos.com/";
              }
            ];
          }
          {
            "NixOS Packages" = [
              {
                icon = "https://search.nixos.org/images/nix-logo.png";
                href = "https://search.nixos.org/packages";
              }
            ];
          }
        ];
      }
    ];

    widgets = [
      {
        datetime = {
          text_size = "xl";
          format = {
            timeStyle = "short";
            dateStyle = "short";
            hour12 = false;
          };
        };
      }
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          uptime = true;
          network = true;
          cputemp = true;
        };
      }
    ];
  };

  services.traefik.dynamicConfigOptions.http = {
    services.homepage.loadBalancer.servers = [
      {
        url = "http://localhost:${toString port}";
      }
    ];

    routers.homepage = {
      rule = "Host(`${config.environment.variables.HOMEPAGE_DOMAIN}`)";
      tls.certResolver = "letsencrypt";
      service = "homepage";
      entrypoints = "websecure";
    };
  };
}
