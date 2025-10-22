{config, ...}: {
  virtualisation.oci-containers.containers.actualbudget = {
    image = "actualbudget/actual-server:latest";
    autoStart = true;
    volumes = ["/srv/actualbudget:/data"];
    ports = ["127.0.0.1:48001:5006"];
  };

  services.traefik.dynamicConfigOptions.http = {
    services.actualbudget.loadBalancer.servers = [
      {
        url = "http://localhost:48001";
      }
    ];

    routers.actualbudget = {
      rule = "Host(`${config.environment.variables.ACTUALBUDGET_DOMAIN}`)";
      tls.certResolver = "letsencrypt";
      service = "actualbudget";
      entrypoints = "websecure";
    };
  };
}
