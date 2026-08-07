{
  config,
  mylib,
  ...
}: let
  port = config.ports.uptimekuma;
in {
  virtualisation.oci-containers.containers.uptimekuma = {
    image = "louislam/uptime-kuma:2.1.0@sha256:da418b1f5655c12d2d62aa3d189117bfad5d83c2ab99bb3e82b2eaaf5246bbc1";
    autoStart = true;
    volumes = [
      "/srv/uptimekuma:/app/data"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];
    ports = ["127.0.0.1:${toString port}:3001"];
    extraOptions = [
      "--health-cmd=node -e \"require('http').get('http://localhost:3001/api/health', r => r.statusCode === 200 ? process.exit(0) : process.exit(1)).on('error', () => process.exit(1))\""
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=5"
      "--health-start-period=30s"
    ];
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "uptimekuma";
    domain = config.environment.variables.UPTIMEKUMA_DOMAIN;
    inherit port;
  };
}
