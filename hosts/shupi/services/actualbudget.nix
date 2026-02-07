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
    extraOptions = [
      "--health-cmd=node -e \"require('http').get('http://localhost:5006/health', r => r.statusCode === 200 ? process.exit(0) : process.exit(1)).on('error', () => process.exit(1))\""
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=5"
      "--health-start-period=30s"
    ];
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "actualbudget";
    domain = config.environment.variables.ACTUALBUDGET_DOMAIN;
    port = port;
  };
}
