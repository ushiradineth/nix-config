{
  config,
  mylib,
  ...
}: let
  port = config.ports.portainer;
in {
  virtualisation.oci-containers.containers.portainer = {
    image = "portainer/portainer-ce:2.33.6";
    autoStart = true;
    volumes = [
      "/srv/portainer:/data"
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
    ports = ["127.0.0.1:${toString port}:9000"];
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "portainer";
    domain = config.environment.variables.PORTAINER_DOMAIN;
    port = port;
  };
}
