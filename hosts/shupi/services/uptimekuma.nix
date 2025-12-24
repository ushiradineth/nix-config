{
  config,
  mylib,
  ...
}: let
  port = config.ports.uptimekuma;
in {
  virtualisation.oci-containers.containers.uptimekuma = {
    image = "louislam/uptime-kuma:latest";
    autoStart = true;
    volumes = ["/srv/uptimekuma:/app/data"];
    ports = ["127.0.0.1:${toString port}:3001"];
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "uptimekuma";
    domain = config.environment.variables.UPTIMEKUMA_DOMAIN;
    port = port;
  };
}
