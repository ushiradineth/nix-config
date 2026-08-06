{
  config,
  mylib,
  myvars,
  ...
}: let
  port = config.ports.homeassistant;
in {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  system.activationScripts.homeAssistantConfig = ''
    install -d -m 0750 /var/lib/hass

    if [ ! -e /var/lib/hass/configuration.yaml ]; then
      cat > /var/lib/hass/configuration.yaml <<'EOF'
    default_config:

    http:
      server_host: 127.0.0.1
      server_port: ${toString port}
      use_x_forwarded_for: true
      trusted_proxies:
        - 127.0.0.1
        - ::1
    EOF
      chmod 0644 /var/lib/hass/configuration.yaml
    fi
  '';

  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant:2026.5.4@sha256:ceb1202133a5a036e8b03e20a10eb113186cc2f871968323c6fc6c3fc4205716";
    autoStart = true;
    environment.TZ = myvars.timezone;
    volumes = [
      "/var/lib/hass:/config"
      "/run/dbus:/run/dbus:ro"
      "/run/udev:/run/udev:ro"
    ];
    extraOptions = [
      "--network=host"
      "--privileged"
    ];
  };

  systemd.services.docker-homeassistant = {
    after = ["dbus.service" "network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "homeassistant";
    domain = config.environment.variables.HOMEASSISTANT_DOMAIN;
    inherit port;
  };
}
