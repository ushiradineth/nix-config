{
  config,
  mylib,
  ...
}: let
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
        "Applications" = {
          style = "row";
          columns = 3;
        };
        "Infrastructure" = {
          style = "row";
          columns = 4;
        };
        "Network & Security" = {
          style = "row";
          columns = 3;
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
        image = "https://sf.shupi.ushira.com/seafhttp/files/ce5e2b0f-5d55-4616-96d9-f96d16795811/2d1baef67bcb2d35e6cbe508c084fe46.png";
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
            "Victoria Metrics" = {
              icon = "https://avatars.githubusercontent.com/u/43720803?s=200&v=4";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}";
              description = "Metrics & Monitoring";
            };
          }
          {
            "Victoria Logs" = {
              icon = "https://avatars.githubusercontent.com/u/43720803?s=200&v=4";
              href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}";
              description = "Log Management";
            };
          }
          {
            Backrest = {
              icon = "https://raw.githubusercontent.com/garethgeorge/backrest/4053b88e7522684a75f4ff69870b156d0255d08f/webui/assets/favicon.svg";
              href = "https://${config.environment.variables.BACKREST_DOMAIN}";
              description = "Backup Management";
            };
          }
          {
            Ntfy = {
              icon = "https://raw.githubusercontent.com/binwiederhier/ntfy/refs/heads/main/web/public/static/images/ntfy.png";
              href = "https://${config.environment.variables.NTFY_DOMAIN}";
              description = "Notifications";
            };
          }
          {
            Alertmanager = {
              icon = "https://avatars.githubusercontent.com/u/3380462?s=120&v=4";
              href = "https://${config.environment.variables.ALERTMANAGER_DOMAIN}";
              description = "Alert Routing";
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
          {
            Wakapi = {
              icon = "https://wakapi.dev/assets/images/icon.svg";
              href = "https://${config.environment.variables.WAKAPI_DOMAIN}";
              description = "Coding Time Tracking";
            };
          }
        ];
      }
    ];

    bookmarks = [
      {
        "Monitoring Queries" = [
          {
            "CPU Usage" = [
              {
                icon = "https://avatars.githubusercontent.com/u/43720803?s=200&v=4";
                abbr = "CPU";
                href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=100%20-%20(avg%20by%20(instance)%20(rate(node_cpu_seconds_total%7Bmode%3D%22idle%22%7D%5B5m%5D))%20*%20100)&g0.range_input=1h&g0.tab=0";
              }
            ];
          }
          {
            "Memory Usage" = [
              {
                icon = "https://avatars.githubusercontent.com/u/43720803?s=200&v=4";
                abbr = "MEM";
                href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=(1%20-%20(node_memory_MemAvailable_bytes%20%2F%20node_memory_MemTotal_bytes))%20*%20100&g0.range_input=1h&g0.tab=0";
              }
            ];
          }
          {
            "Disk Usage" = [
              {
                icon = "https://avatars.githubusercontent.com/u/43720803?s=200&v=4";
                abbr = "DISK";
                href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=100%20-%20((node_filesystem_avail_bytes%7Bmountpoint%3D%22%2F%22%7D%20%2F%20node_filesystem_size_bytes%7Bmountpoint%3D%22%2F%22%7D)%20*%20100)&g0.range_input=1h&g0.tab=0";
              }
            ];
          }
          {
            "Network Traffic" = [
              {
                icon = "https://avatars.githubusercontent.com/u/43720803?s=200&v=4";
                abbr = "NET";
                href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=rate(node_network_receive_bytes_total%5B5m%5D)&g0.range_input=1h&g0.tab=0";
              }
            ];
          }
        ];
      }
      {
        "Log Queries" = [
          {
            "All Logs (5m)" = [
              {
                icon = "https://avatars.githubusercontent.com/u/43720803?s=200&v=4";
                abbr = "ALL";
                href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}/select/vmui/?#/?query=*&g0.range_input=5m&g0.relative_time=last_5_minutes";
              }
            ];
          }
          {
            "Error Logs" = [
              {
                icon = "https://avatars.githubusercontent.com/u/43720803?s=200&v=4";
                abbr = "ERR";
                href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}/select/vmui/?#/?query=error%20OR%20ERROR%20OR%20failed%20OR%20FAILED&g0.range_input=1h&g0.relative_time=last_1_hour";
              }
            ];
          }
          {
            "Docker Logs" = [
              {
                icon = "https://avatars.githubusercontent.com/u/43720803?s=200&v=4";
                abbr = "DOCK";
                href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}/select/vmui/?#/?query=%7Bcontainer_name%21%3D%22%22%7D&g0.range_input=30m&g0.relative_time=last_30_minutes";
              }
            ];
          }
          {
            "System Services" = [
              {
                icon = "https://avatars.githubusercontent.com/u/43720803?s=200&v=4";
                abbr = "SYS";
                href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}/select/vmui/?#/?query=%7B_SYSTEMD_UNIT%3D~%22.%2B%22%7D&g0.range_input=30m&g0.relative_time=last_30_minutes";
              }
            ];
          }
        ];
      }
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

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "homepage";
    domain = config.environment.variables.HOMEPAGE_DOMAIN;
    port = port;
  };
}
