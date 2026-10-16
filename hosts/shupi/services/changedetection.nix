{
  config,
  lib,
  mylib,
  ...
}: let
  port = config.ports.changedetection;
  domain = config.environment.variables.CHANGEDETECTION_DOMAIN;
  route = mylib.traefikHelpers.mkTraefikRoute {
    name = "changedetection";
    host = "127.0.0.1";
    inherit domain port;
  };
in {
  services.changedetection-io = {
    enable = true;
    datastorePath = "/srv/changedetection";
    listenAddress = "127.0.0.1";
    inherit port;
    baseURL = "https://${domain}";
    behindProxy = true;
  };

  services.traefik.dynamicConfigOptions.http = lib.recursiveUpdate route {
    middlewares.changedetection-tailnet.ipAllowList.sourceRange = ["100.64.0.0/10" "fd7a:115c:a1e0::/48"];
    routers.changedetection.middlewares = ["changedetection-tailnet"];
  };
}
