{
  config,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.umami;
  domain = config.environment.variables.UMAMI_DOMAIN;
in {
  age.secrets.umami-db-password = {
    file = "${mysecrets}/${hostname}/umami-db-password.age";
    mode = "0400";
  };

  age.secrets.umami-app-secret = {
    file = "${mysecrets}/${hostname}/umami-app-secret.age";
    mode = "0400";
  };

  # Create Docker network for Umami
  systemd.services.init-umami-network = {
    description = "Create Docker network for Umami";
    after = ["docker.service" "docker.socket"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${config.virtualisation.docker.package}/bin/docker network inspect umami >/dev/null 2>&1 || \
      ${config.virtualisation.docker.package}/bin/docker network create umami
    '';
  };

  # Ensure containers wait for network to be created
  systemd.services.docker-umami-db = {
    after = ["init-umami-network.service"];
    requires = ["init-umami-network.service"];
  };
  systemd.services.docker-umami-app = {
    after = ["init-umami-network.service"];
    requires = ["init-umami-network.service"];
  };

  # Create env files for Umami containers
  system.activationScripts.umami-env = ''
    mkdir -p /var/lib/umami

    # PostgreSQL password
    DB_PASSWORD=$(cat ${config.age.secrets.umami-db-password.path})

    # App secret
    APP_SECRET=$(cat ${config.age.secrets.umami-app-secret.path})

    # PostgreSQL env file
    echo "POSTGRES_DB=umami" > /var/lib/umami/postgres.env
    echo "POSTGRES_USER=umami" >> /var/lib/umami/postgres.env
    echo "POSTGRES_PASSWORD=$DB_PASSWORD" >> /var/lib/umami/postgres.env
    chmod 600 /var/lib/umami/postgres.env

    # Umami app env file
    echo "DATABASE_URL=postgresql://umami:$DB_PASSWORD@umami-db:5432/umami" > /var/lib/umami/app.env
    echo "DATABASE_TYPE=postgresql" >> /var/lib/umami/app.env
    echo "APP_SECRET=$APP_SECRET" >> /var/lib/umami/app.env
    echo "DISABLE_TELEMETRY=1" >> /var/lib/umami/app.env
    chmod 600 /var/lib/umami/app.env
  '';

  # PostgreSQL container for Umami
  virtualisation.oci-containers.containers.umami-db = {
    image = "postgres:15-alpine";
    autoStart = true;
    volumes = [
      "/srv/umami/db:/var/lib/postgresql/data"
    ];
    extraOptions = [
      "--network=umami"
      "--health-cmd=pg_isready -U umami"
      "--health-interval=10s"
      "--health-start-period=30s"
      "--health-timeout=5s"
      "--health-retries=5"
    ];
    environmentFiles = ["/var/lib/umami/postgres.env"];
  };

  # Umami application container
  virtualisation.oci-containers.containers.umami-app = {
    image = "ghcr.io/umami-software/umami:postgresql-latest";
    autoStart = true;
    dependsOn = ["umami-db"];
    ports = ["127.0.0.1:${toString port}:3000"];
    extraOptions = ["--network=umami"];
    environmentFiles = ["/var/lib/umami/app.env"];
  };

  # Traefik configuration for reverse proxy
  services.traefik.dynamicConfigOptions.http = {
    services.umami.loadBalancer.servers = [
      {
        url = "http://localhost:${toString port}";
      }
    ];

    routers.umami = {
      rule = "Host(`${domain}`)";
      tls.certResolver = "letsencrypt";
      service = "umami";
      entrypoints = "websecure";
    };
  };
}
