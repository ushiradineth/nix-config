{config, ...}: {
  virtualisation.oci-containers.containers.portainer = {
    image = "portainer/portainer-ce";
    autoStart = true;
    volumes = [
      "/srv/portainer:/data"
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
    ports = ["127.0.0.1:48002:9000"];
  };

  services.traefik.dynamicConfigOptions.http = {
    services.portainer.loadBalancer.servers = [
      {
        url = "http://localhost:48002";
      }
    ];

    routers.portainer = {
      rule = "Host(`${config.environment.variables.PORTAINER_DOMAIN}`)";
      tls.certResolver = "letsencrypt";
      service = "portainer";
      entrypoints = "websecure";
    };
  };
}
