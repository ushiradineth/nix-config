{
  config,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.infisical;
  domain = config.environment.variables.INFISICAL_DOMAIN;
in {
  age.secrets.infisical-db-password = {
    file = "${mysecrets}/${hostname}/infisical-db-password.age";
    mode = "0400";
  };

  age.secrets.infisical-encryption-key = {
    file = "${mysecrets}/${hostname}/infisical-encryption-key.age";
    mode = "0400";
  };

  age.secrets.infisical-auth-secret = {
    file = "${mysecrets}/${hostname}/infisical-auth-secret.age";
    mode = "0400";
  };

  # Create Docker network for Infisical
  systemd.services.init-infisical-network = {
    description = "Create Docker network for Infisical";
    after = ["docker.service" "docker.socket"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${config.virtualisation.docker.package}/bin/docker network inspect infisical >/dev/null 2>&1 || \
      ${config.virtualisation.docker.package}/bin/docker network create infisical
    '';
  };

  # Ensure containers wait for network to be created
  systemd.services.docker-infisical-db = {
    after = ["init-infisical-network.service"];
    requires = ["init-infisical-network.service"];
  };
  systemd.services.docker-infisical-redis = {
    after = ["init-infisical-network.service"];
    requires = ["init-infisical-network.service"];
  };
  systemd.services.docker-infisical-backend = {
    after = ["init-infisical-network.service"];
    requires = ["init-infisical-network.service"];
  };

  # Create env files for Infisical containers
  system.activationScripts.infisical-env = ''
    mkdir -p /var/lib/infisical

    # Read secrets (trim whitespace)
    DB_PASSWORD=$(cat ${config.age.secrets.infisical-db-password.path} | tr -d '[:space:]')
    ENCRYPTION_KEY=$(cat ${config.age.secrets.infisical-encryption-key.path} | tr -d '[:space:]')
    AUTH_SECRET=$(cat ${config.age.secrets.infisical-auth-secret.path} | tr -d '[:space:]')

    # PostgreSQL env file
    echo "POSTGRES_DB=infisical" > /var/lib/infisical/postgres.env
    echo "POSTGRES_USER=infisical" >> /var/lib/infisical/postgres.env
    echo "POSTGRES_PASSWORD=$DB_PASSWORD" >> /var/lib/infisical/postgres.env
    chmod 600 /var/lib/infisical/postgres.env

    # Infisical backend env file
    echo "NODE_ENV=production" > /var/lib/infisical/backend.env
    echo "ENCRYPTION_KEY=$ENCRYPTION_KEY" >> /var/lib/infisical/backend.env
    echo "AUTH_SECRET=$AUTH_SECRET" >> /var/lib/infisical/backend.env
    echo "DB_CONNECTION_URI=postgres://infisical:$DB_PASSWORD@infisical-db:5432/infisical" >> /var/lib/infisical/backend.env
    echo "REDIS_URL=redis://infisical-redis:6379" >> /var/lib/infisical/backend.env
    echo "SITE_URL=https://${domain}" >> /var/lib/infisical/backend.env
    chmod 600 /var/lib/infisical/backend.env
  '';

  # PostgreSQL container for Infisical
  virtualisation.oci-containers.containers.infisical-db = {
    image = "postgres:14-alpine";
    autoStart = true;
    volumes = [
      "/srv/infisical/postgres:/var/lib/postgresql/data"
    ];
    extraOptions = [
      "--network=infisical"
      "--health-cmd=pg_isready -U infisical"
      "--health-interval=5s"
      "--health-timeout=10s"
      "--health-retries=10"
      "--health-start-period=30s"
    ];
    environmentFiles = ["/var/lib/infisical/postgres.env"];
  };

  # Redis container for Infisical
  virtualisation.oci-containers.containers.infisical-redis = {
    image = "redis:latest";
    autoStart = true;
    volumes = [
      "/srv/infisical/redis:/data"
    ];
    extraOptions = ["--network=infisical"];
    environment = {
      ALLOW_EMPTY_PASSWORD = "yes";
    };
  };

  # Infisical backend container
  virtualisation.oci-containers.containers.infisical-backend = {
    image = "infisical/infisical:latest";
    autoStart = true;
    dependsOn = ["infisical-db" "infisical-redis"];
    ports = ["127.0.0.1:${toString port}:8080"];
    extraOptions = ["--network=infisical"];
    environmentFiles = ["/var/lib/infisical/backend.env"];
  };

  # Traefik configuration for reverse proxy
  services.traefik.dynamicConfigOptions.http = {
    services.infisical.loadBalancer.servers = [
      {
        url = "http://localhost:${toString port}";
      }
    ];

    routers.infisical = {
      rule = "Host(`${domain}`)";
      tls.certResolver = "letsencrypt";
      service = "infisical";
      entrypoints = "websecure";
    };
  };
}
