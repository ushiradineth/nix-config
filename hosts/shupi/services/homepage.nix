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

    environmentFiles = [
      (builtins.toFile "homepage-env" ''
        HOMEPAGE_ALLOWED_HOSTS=${config.environment.variables.HOMEPAGE_DOMAIN}
      '')
    ];

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
          columns = 2;
        };
        "Infrastructure" = {
          style = "row";
          columns = 4;
        };
        "Network & Security" = {
          style = "row";
          columns = 3;
        };
        "Observability" = {
          style = "row";
          columns = 3;
        };
      };
      quicklaunch = {
        searchDescriptions = true;
        hideInternetSearch = false;
      };
      favicon = "https://ushira.com/favicon.svg";
      cardBlur = "lg";
      background = {
        image = "https://sf.shupi.ushira.com/seafhttp/f/17ce8a9973d542b58e98/?op=view";
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
              icon = "portainer-dark.png";
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
              icon = "victoriametrics-light.png";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}";
              description = "Metrics & Monitoring";
            };
          }
          {
            "Victoria Logs" = {
              icon = "victorialogs.png";
              href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}";
              description = "Log Management";
            };
          }
          {
            Backrest = {
              icon = "backrest.svg";
              href = "https://${config.environment.variables.BACKREST_DOMAIN}";
              description = "Backup Management";
            };
          }
          {
            Ntfy = {
              icon = "ntfy.png";
              href = "https://${config.environment.variables.NTFY_DOMAIN}";
              description = "Notifications";
            };
          }
          {
            Alertmanager = {
              icon = "alertmanager-dark.png";
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
              icon = "tailscale-light.png";
              href = "https://login.tailscale.com/";
              description = "Tailscale Dashboard";
            };
          }
          {
            Cloudflared = {
              icon = "cloudflared.png";
              href = "https://dash.cloudflare.com/";
              description = "Cloudflare Dashboard";
            };
          }
        ];
      }
      {
        "Applications" = [
          {
            "Paperclip" = {
              icon = "https://cdn.jsdelivr.net/gh/selfhst/icons/png/paperclip-ai-light.png";
              href = "https://paperclip.shupi.ushira.com";
              description = "Agent Management Platform";
            };
          }
          {
            "SnapOtter" = {
              icon = "https://cdn.jsdelivr.net/gh/selfhst/icons/png/snapotter.png";
              href = "https://snapotter.shupi.ushira.com";
              description = "Local File Processing";
            };
          }
          {
            "Actual Budget" = {
              icon = "actual-budget.png";
              href = "https://${config.environment.variables.ACTUALBUDGET_DOMAIN}";
              description = "Budget Management";
            };
          }
          {
            Seafile = {
              icon = "seafile.png";
              href = "https://${config.environment.variables.SEAFILE_DOMAIN}";
              description = "Cloud Storage";
            };
          }
          {
            Immich = {
              icon = "immich.png";
              href = "https://${config.environment.variables.IMMICH_DOMAIN}";
              description = "Photo Management";
            };
          }
          {
            Umami = {
              icon = "umami-light.png";
              href = "https://${config.environment.variables.UMAMI_DOMAIN}";
              description = "Privacy-focused Analytics";
            };
          }
          {
            Wakapi = {
              icon = "wakapi.png";
              href = "https://${config.environment.variables.WAKAPI_DOMAIN}";
              description = "Coding Time Tracking";
            };
          }
          {
            Karakeep = {
              icon = "karakeep.png";
              href = "https://${config.environment.variables.KARAKEEP_DOMAIN}";
              description = "Bookmark Manager";
            };
          }
          {
            "Change Detection" = {
              icon = "changedetection.png";
              href = config.services.changedetection-io.baseURL;
              description = "Website Change Monitoring";
            };
          }
          {
            Forgejo = {
              icon = "forgejo.png";
              href = "https://${config.environment.variables.FORGEJO_DOMAIN}";
              description = "Git Hosting & Mirrors";
            };
          }
          {
            "Home Assistant" = {
              icon = "home-assistant.png";
              href = "https://${config.environment.variables.HOMEASSISTANT_DOMAIN}";
              description = "Smart Home Control";
            };
          }
        ];
      }
      {
        "Observability" = [
          # Row 1
          {
            "CPU Usage" = {
              icon = "victoriametrics-light.png";
              description = "Host CPU (%)";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=100%20-%20(avg%20by%20(instance)%20(rate(node_cpu_seconds_total%7Bmode%3D%22idle%22%7D%5B5m%5D))%20*%20100)&g0.range_input=1h&g0.tab=0";
            };
          }
          {
            "Container CPU" = {
              icon = "victoriametrics-light.png";
              description = "Container CPU (%)";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=sum%20by%20(name)%20(rate(container_cpu_usage_seconds_total%7Bname!%3D%22%22%7D%5B5m%5D))%20*%20100&g0.range_input=1h&g0.tab=0";
            };
          }
          {
            "All Logs" = {
              icon = "victoriametrics-light.png";
              description = "All logs (5m)";
              href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}/select/vmui/?#/?query=*&g0.range_input=5m&g0.relative_time=last_5_minutes";
            };
          }
          # Row 2
          {
            "Memory Usage" = {
              icon = "victoriametrics-light.png";
              description = "Host memory (%)";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=(1%20-%20(node_memory_MemAvailable_bytes%20%2F%20node_memory_MemTotal_bytes))%20*%20100&g0.range_input=1h&g0.tab=0";
            };
          }
          {
            "Container Memory" = {
              icon = "victoriametrics-light.png";
              description = "Container memory (MB)";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=sum%20by%20(name)%20(container_memory_usage_bytes%7Bname!%3D%22%22%7D)%20%2F%201024%20%2F%201024&g0.range_input=1h&g0.tab=0";
            };
          }
          {
            "Error Logs" = {
              icon = "victoriametrics-light.png";
              description = "Errors and failures (1h)";
              href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}/select/vmui/?#/?query=error%20OR%20ERROR%20OR%20failed%20OR%20FAILED&g0.range_input=1h&g0.relative_time=last_1_hour";
            };
          }
          # Row 3
          {
            "Disk Usage" = {
              icon = "victoriametrics-light.png";
              description = "Root filesystem (%)";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=100%20-%20((node_filesystem_avail_bytes%7Bmountpoint%3D%22%2F%22%7D%20%2F%20node_filesystem_size_bytes%7Bmountpoint%3D%22%2F%22%7D)%20*%20100)&g0.range_input=1h&g0.tab=0";
            };
          }
          {
            "Container Net RX" = {
              icon = "victoriametrics-light.png";
              description = "Container network RX (KB/s)";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=sum%20by%20(name)%20(rate(container_network_receive_bytes_total%7Bname!%3D%22%22%7D%5B5m%5D))%20%2F%201024&g0.range_input=1h&g0.tab=0";
            };
          }
          {
            "Warning Logs" = {
              icon = "victoriametrics-light.png";
              description = "Warnings (1h)";
              href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}/select/vmui/?#/?query=WARN%20OR%20WARNING%20OR%20warn%20OR%20warning&g0.range_input=1h&g0.relative_time=last_1_hour";
            };
          }
          # Row 4
          {
            "Network Traffic" = {
              icon = "victoriametrics-light.png";
              description = "Host network RX (B/s)";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=rate(node_network_receive_bytes_total%5B5m%5D)&g0.range_input=1h&g0.tab=0";
            };
          }
          {
            "Container Net TX" = {
              icon = "victoriametrics-light.png";
              description = "Container network TX (KB/s)";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=sum%20by%20(name)%20(rate(container_network_transmit_bytes_total%7Bname!%3D%22%22%7D%5B5m%5D))%20%2F%201024&g0.range_input=1h&g0.tab=0";
            };
          }
          {
            "Docker Logs" = {
              icon = "victoriametrics-light.png";
              description = "Container logs (30m)";
              href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}/select/vmui/?#/?query=%7Bcontainer_name%21%3D%22%22%7D&g0.range_input=30m&g0.relative_time=last_30_minutes";
            };
          }
          # Row 5
          {
            "Load Average" = {
              icon = "victoriametrics-light.png";
              description = "1-minute load average";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=node_load1&g0.range_input=1h&g0.tab=0";
            };
          }
          {
            "Active Alerts" = {
              icon = "victoriametrics-light.png";
              description = "Firing alerts";
              href = "https://${config.environment.variables.VICTORIAMETRICS_DOMAIN}/vmui/#/?g0.expr=ALERTS%7Balertstate%3D%22firing%22%7D&g0.range_input=1h&g0.tab=0";
            };
          }
          {
            "System Services" = {
              icon = "victoriametrics-light.png";
              description = "Systemd logs (30m)";
              href = "https://${config.environment.variables.VICTORIALOGS_DOMAIN}/select/vmui/?#/?query=%7B_SYSTEMD_UNIT%3D~%22.%2B%22%7D&g0.range_input=30m&g0.relative_time=last_30_minutes";
            };
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
    inherit port;
  };
}
