{config, ...}: let
  port = config.ports.grafana;
in {
  services.grafana = {
    enable = true;
    settings.server = {
      domain = "0.0.0.0";
      http_port = port;
      http_addr = "0.0.0.0";
    };
    provision = {
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
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

  services.traefik.dynamicConfigOptions.http = {
    services.grafana.loadBalancer.servers = [
      {
        url = "http://localhost:${toString port}";
      }
    ];

    routers.grafana = {
      rule = "Host(`${config.environment.variables.GRAFANA_DOMAIN}`)";
      tls.certResolver = "letsencrypt";
      service = "grafana";
      entrypoints = "websecure";
    };
  };
}
