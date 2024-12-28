{config, ...}: {
  services.prometheus = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9090;

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "cpu"
          "cpufreq"
          "diskstats"
          "meminfo"
          "netdev"
          "netstat"
          "stat"
          "ethtool"
          "lnstat"
          "logind"
          "perf"
          "systemd"
        ];
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["0.0.0.0:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings.server = {
      domain = "0.0.0.0";
      http_port = 3000;
      http_addr = "0.0.0.0";
    };
    provision = {
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://${toString config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
            access = "proxy";
          }
        ];
      };
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "default";
            orgId = 1;
            folder = "";
            folderUid = "";
            type = "file";
            disableDeletion = false;
            editable = true;
            options = {
              path = "/etc/grafana/dashboards";
            };
          }
        ];
      };
    };
  };

  environment.etc."grafana/dashboards/node-exporter.json".source = builtins.fetchurl {
    url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
    sha256 = "sha256:0qza4j8lywrj08bqbww52dgh2p2b9rkhq5p313g72i57lrlkacfl";
  };

  services.nginx.virtualHosts.${config.services.grafana.domain} = {
    locations."/" = {
      proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
    };
  };
}
