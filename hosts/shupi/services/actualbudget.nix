{
  config,
  mylib,
  ...
}: let
  port = config.ports.actualbudget;
in {
  virtualisation.oci-containers.containers.actualbudget = {
    image = "actualbudget/actual-server:latest";
    autoStart = true;
    volumes = ["/srv/actualbudget:/data"];
    ports = ["127.0.0.1:${toString port}:5006"];
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "actualbudget";
    domain = config.environment.variables.ACTUALBUDGET_DOMAIN;
    port = port;
  };
}
