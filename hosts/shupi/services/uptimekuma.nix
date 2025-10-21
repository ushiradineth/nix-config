{config, ...}: {
  virtualisation.oci-containers.containers.uptimekuma = {
    image = "louislam/uptime-kuma:latest";
    autoStart = true;
    volumes = ["/srv/uptimekuma:/app/data"];
    ports = ["127.0.0.1:48003:3001"];
  };

  services.traefik.dynamicConfigOptions.http = {
    services.uptimekuma.loadBalancer.servers = [
      {
        url = "http://localhost:48003";
      }
    ];

    routers.uptimekuma = {
      rule = "Host(`${config.environment.variables.UPTIMEKUMA_DOMAIN}`)";
      tls = {
        certResolver = "letsencrypt";
      };
      service = "uptimekuma";
      entrypoints = "websecure";
    };
  };
}
