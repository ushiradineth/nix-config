{
  config,
  mylib,
  ...
}: let
  port = config.ports.homeassistant;
in {
  services.home-assistant = {
    enable = true;
    configWritable = true;
    openFirewall = false;

    extraComponents = [
      "default_config"
      "dhcp"
      "esphome"
      "govee_light_local"
      "ssdp"
      "zeroconf"
    ];

    config = {
      default_config = {};

      http = {
        server_host = "127.0.0.1";
        server_port = port;
        use_x_forwarded_for = true;
        trusted_proxies = ["127.0.0.1" "::1"];
      };
    };
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "homeassistant";
    domain = config.environment.variables.HOMEASSISTANT_DOMAIN;
    inherit port;
  };
}
