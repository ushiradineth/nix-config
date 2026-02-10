{
  config,
  pkgs,
  lib,
  mylib,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.ntfy;
  domain = config.environment.variables.NTFY_DOMAIN;
in {
  age.secrets.ntfy-credentials = {
    file = "${mysecrets}/${hostname}/ntfy-credentials.age";
    mode = "0400";
  };

  # Storage directory
  systemd.tmpfiles.rules = [
    "d /srv/ntfy 0755 root root -"
    "d /srv/ntfy/cache 0755 root root -"
    "d /var/lib/ntfy 0755 root root -"
  ];

  # Ntfy container
  virtualisation.oci-containers.containers.ntfy = {
    image = "binwiederhier/ntfy:v2.17.0";
    autoStart = true;
    ports = ["127.0.0.1:${toString port}:80"];
    extraOptions = [
      "--network=monitoring"
      "--health-cmd=wget -qO- http://localhost:80/v1/health || exit 1"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=5"
      "--health-start-period=10s"
    ];
    volumes = [
      "/srv/ntfy/cache:/var/cache/ntfy"
      "/srv/ntfy/server.yml:/etc/ntfy/server.yml:ro"
    ];
    cmd = ["serve"];
  };

  # Create ntfy configuration file + basic auth file for Traefik
  system.activationScripts.ntfyConfig = ''
    mkdir -p /srv/ntfy
    mkdir -p /var/lib/ntfy

    NTFY_AUTH=$(cat ${config.age.secrets.ntfy-credentials.path} | tr -d '[:space:]')
    NTFY_USER=''${NTFY_AUTH%%:*}
    NTFY_PASS=''${NTFY_AUTH#*:}
    NTFY_HASH=$(${pkgs.openssl}/bin/openssl passwd -apr1 "$NTFY_PASS")
    echo "$NTFY_USER:$NTFY_HASH" > /var/lib/ntfy/htpasswd
    chown traefik:traefik /var/lib/ntfy/htpasswd
    chmod 440 /var/lib/ntfy/htpasswd

    cat > /srv/ntfy/server.yml <<'EOF'
    # Base URL for ntfy server
    base-url: "https://${domain}"

    # Listen on all interfaces (container internal)
    listen-http: ":80"

    # Cache configuration
    cache-file: "/var/cache/ntfy/cache.db"
    cache-duration: "12h"

    # Authentication handled by Traefik basic auth

    # Rate limiting
    visitor-request-limit-burst: 60
    visitor-request-limit-replenish: "5s"
    visitor-message-daily-limit: 500

    # Enable web UI
    enable-login: false
    enable-signup: false
    enable-reservations: false

    # Attachment settings (disabled for security)
    attachment-cache-dir: ""

    # Disable upstream base URL (self-hosted only)
    upstream-base-url: ""

    # Log level
    log-level: info
    EOF
    chmod 644 /srv/ntfy/server.yml
  '';

  # Traefik route
  services.traefik.dynamicConfigOptions.http = lib.mkMerge [
    (mylib.traefikHelpers.mkTraefikRoute {
      name = "ntfy";
      inherit domain port;
    })
    {
      middlewares."ntfy-auth".basicAuth.usersFile = "/var/lib/ntfy/htpasswd";
      routers.ntfy.middlewares = ["ntfy-auth"];
    }
  ];
}
