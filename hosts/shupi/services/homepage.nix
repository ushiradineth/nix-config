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

    customCSS = ''
      #revalidate {
        display: none;
      }

      dialog.alias-search > ul {
        display: none;
      }

      .alias-search-result {
        padding: 0.5rem;
      }

      .alias-search-result button {
        width: 100%;
        padding: 0.75rem 1rem;
        border-radius: 0.375rem;
        text-align: left;
      }

      .alias-search-result button[data-active="true"],
      .alias-search-result button:hover {
        background: rgb(128 128 128 / 20%);
      }
    '';

    customJS = ''
      const searchInput = '[role="dialog"][aria-modal="true"] input';
      const destinations = {
        n: { name: "Nix Packages", url: "https://search.nixos.org/packages?channel=25.11" },
        no: { name: "NixOS Options", url: "https://search.nixos.org/options?channel=25.11" },
        hm: { name: "Home Manager Options", url: "https://home-manager-options.extranix.com/?release=release-25.11" },
      };
      let selectedAlias = 0;

      function getAliases(value) {
        const match = value.trimStart().match(/^([!@])(\w*)(?:\s+(.*))?$/is);
        if (!match) return null;
        const prefix = match[2].toLowerCase();
        const query = (match[3] || "").trim();
        const keys = Object.keys(destinations).filter((key) =>
          match[3] !== undefined ? key === prefix : key.startsWith(prefix)
        );
        if (!keys.length) return null;
        return keys.map((key) => {
          const destination = destinations[key];
          const url = new URL(destination.url);
          url.searchParams.set("query", query);
          return { name: destination.name, shortcut: match[1] + key, query, url: url.href };
        });
      }

      function openAlias(input, alias) {
        if (!alias) return;
        if (!alias.query) {
          // Use the native setter so React notices the completion as an input change.
          const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set;
          setter.call(input, alias.shortcut + " ");
          input.dispatchEvent(new Event("input", { bubbles: true }));
          input.focus();
          return;
        }
        window.open(alias.url, "_blank", "noreferrer");
        input.focus();
        input.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
      }

      function showAlias(input) {
        const dialog = input.closest("dialog");
        if (!dialog) return;
        const aliases = getAliases(input.value);
        dialog.classList.toggle("alias-search", Boolean(aliases));
        let result = dialog.querySelector(".alias-search-result");
        if (!aliases) {
          result?.remove();
          return;
        }
        if (!result) {
          result = document.createElement("div");
          result.className = "alias-search-result";
          result.setAttribute("aria-live", "polite");
          input.after(result);
        }
        selectedAlias = Math.min(selectedAlias, aliases.length - 1);
        result.replaceChildren();
        aliases.forEach((alias, index) => {
          const button = document.createElement("button");
          button.type = "button";
          button.dataset.active = String(index === selectedAlias);
          button.textContent = alias.shortcut + " — " + alias.name + " (25.11)" +
            (alias.query ? ": " + alias.query : " — Type a query");
          button.addEventListener("click", () => openAlias(input, alias));
          button.addEventListener("keydown", (event) => {
            if (event.key === "Escape") {
              input.focus();
              input.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
            }
          });
          result.append(button);
        });
      }

      for (const type of ["input", "focusin"]) {
        document.addEventListener(type, (event) => {
          if (event.target.matches(searchInput)) {
            selectedAlias = 0;
            // Wait for React's controlled input update before updating our result.
            queueMicrotask(() => showAlias(event.target));
          }
        }, true);
      }

      document.addEventListener("keydown", (event) => {
        if (event.isComposing || event.repeat || !event.target.matches(searchInput)) return;
        const aliases = getAliases(event.target.value);
        if (!aliases) return;
        if (!["Enter", "ArrowDown", "ArrowUp"].includes(event.key)) return;

        // Keep hidden Google results from receiving navigation or activation.
        event.preventDefault();
        event.stopImmediatePropagation();
        if (event.key === "Enter") {
          openAlias(event.target, aliases[selectedAlias]);
        } else {
          selectedAlias = (selectedAlias + (event.key === "ArrowDown" ? 1 : aliases.length - 1)) % aliases.length;
          showAlias(event.target);
        }
      }, true);
    '';

    environmentFiles = [
      (builtins.toFile "homepage-env" ''
        HOMEPAGE_ALLOWED_HOSTS=${config.environment.variables.HOMEPAGE_DOMAIN}
      '')
    ];

    settings = {
      title = "shupi";
      theme = "dark";
      color = "neutral";
      headerStyle = "boxed";
      hideErrors = false;
      showStats = true;
      statusStyle = "dot";
      disableUpdateCheck = true;
      hideVersion = true;
      disableIndexing = true;
      cardStyle = "hairline";
      blockStyle = "refined";
      useEqualHeights = false;
      language = "en-GB";

      # A list preserves display order; Nix attribute sets sort keys alphabetically.
      layout = [
        {
          "Applications" = {
            style = "row";
            columns = 5;
          };
        }
        {
          "Monitoring & Alerts" = {
            style = "row";
            columns = 5;
          };
        }
        {
          "Infrastructure & Network" = {
            style = "row";
            columns = 3;
          };
        }
        {
          "Diagnostics" = {
            style = "row";
            columns = 3;
          };
        }
      ];
      quicklaunch = {
        searchDescriptions = true;
        hideInternetSearch = false;
        showSearchSuggestions = true;
        provider = "google";
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
        "Monitoring & Alerts" = [
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
        "Infrastructure & Network" = [
          {
            Portainer = {
              icon = "portainer-dark.png";
              href = "https://${config.environment.variables.PORTAINER_DOMAIN}";
              description = "Docker Management";
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
            Traefik = {
              icon = "traefik.png";
              href = "https://${config.environment.variables.TRAEFIK_DOMAIN}";
              description = "Reverse Proxy Dashboard";
            };
          }
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
            "Actual Budget" = {
              icon = "actual-budget.png";
              href = "https://${config.environment.variables.ACTUALBUDGET_DOMAIN}";
              description = "Budget Management";
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
          {
            "Change Detection" = {
              icon = "changedetection.png";
              href = config.services.changedetection-io.baseURL;
              description = "Website Change Monitoring";
            };
          }
          {
            "SnapOtter" = {
              icon = "https://cdn.jsdelivr.net/gh/selfhst/icons/png/snapotter.png";
              href = "https://${config.environment.variables.SNAPOTTER_DOMAIN}";
              description = "Local File Processing";
            };
          }
        ];
      }
      {
        "Diagnostics" = [
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
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          uptime = true;
          network = true;
          cputemp = true;
        };
      }
      {
        datetime = {
          text_size = "xl";
          locale = "en-GB";
          format = {
            hour = "2-digit";
            minute = "2-digit";
            second = "2-digit";
            weekday = "short";
            day = "2-digit";
            month = "short";
            hour12 = false;
          };
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
