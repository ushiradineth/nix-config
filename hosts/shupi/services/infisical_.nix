{
  config,
  pkgs,
  lib,
  mylib,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.infisical;
  domain = config.environment.variables.INFISICAL_DOMAIN;
  emailDomain = config.environment.variables.EMAIL_DOMAIN;
  smtpHost = config.environment.variables.SMTP_HOST;
  smtpPort = config.environment.variables.SMTP_PORT;
  smtpUser = config.environment.variables.SMTP_USER;
in
  lib.mkMerge [
    {
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

      age.secrets.resend-api-key = {
        file = "${mysecrets}/${hostname}/resend-api-key.age";
        mode = "0400";
      };

      system.activationScripts.infisical-env = ''
        mkdir -p /var/lib/infisical

        DB_PASSWORD=$(cat ${config.age.secrets.infisical-db-password.path} | tr -d '[:space:]')
        ENCRYPTION_KEY=$(cat ${config.age.secrets.infisical-encryption-key.path} | tr -d '[:space:]')
        AUTH_SECRET=$(cat ${config.age.secrets.infisical-auth-secret.path} | tr -d '[:space:]')
        RESEND_API_KEY=$(cat ${config.age.secrets.resend-api-key.path} | tr -d '[:space:]')

        echo "POSTGRES_DB=infisical" > /var/lib/infisical/postgres.env
        echo "POSTGRES_USER=infisical" >> /var/lib/infisical/postgres.env
        echo "POSTGRES_PASSWORD=$DB_PASSWORD" >> /var/lib/infisical/postgres.env
        chmod 600 /var/lib/infisical/postgres.env

        echo "NODE_ENV=production" > /var/lib/infisical/backend.env
        echo "ENCRYPTION_KEY=$ENCRYPTION_KEY" >> /var/lib/infisical/backend.env
        echo "AUTH_SECRET=$AUTH_SECRET" >> /var/lib/infisical/backend.env
        echo "DB_CONNECTION_URI=postgres://infisical:$DB_PASSWORD@infisical-db:5432/infisical" >> /var/lib/infisical/backend.env
        echo "REDIS_URL=redis://infisical-redis:6379" >> /var/lib/infisical/backend.env
        echo "SITE_URL=https://${domain}" >> /var/lib/infisical/backend.env
        echo "SMTP_HOST=${smtpHost}" >> /var/lib/infisical/backend.env
        echo "SMTP_PORT=${smtpPort}" >> /var/lib/infisical/backend.env
        echo "SMTP_USERNAME=${smtpUser}" >> /var/lib/infisical/backend.env
        echo "SMTP_PASSWORD=$RESEND_API_KEY" >> /var/lib/infisical/backend.env
        echo "SMTP_FROM_ADDRESS=infisical@${emailDomain}" >> /var/lib/infisical/backend.env
        echo "SMTP_FROM_NAME=Infisical" >> /var/lib/infisical/backend.env
        chmod 600 /var/lib/infisical/backend.env
      '';

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

      virtualisation.oci-containers.containers.infisical-backend = {
        image = "infisical/infisical:latest";
        autoStart = true;
        dependsOn = ["infisical-db" "infisical-redis"];
        ports = ["127.0.0.1:${toString port}:8080"];
        extraOptions = ["--network=infisical"];
        environmentFiles = ["/var/lib/infisical/backend.env"];
      };
    }
    (mylib.dockerHelpers.mkDockerNetwork {
      config = config;
      name = "infisical";
    })
    (mylib.dockerHelpers.mkContainerNetworkDeps {
      name = "infisical";
      containers = ["infisical-db" "infisical-redis" "infisical-backend"];
    })
    {
      services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
        name = "infisical";
        domain = domain;
        port = port;
      };
    }
    (mylib.dockerHelpers.mkDatabaseDumpService {
      config = config;
      pkgs = pkgs;
      name = "infisical";
      description = "Dump Infisical PostgreSQL database";
      containerDeps = ["infisical-db"];
      dumpCommand = ''
        ${config.virtualisation.docker.package}/bin/docker exec infisical-db \
          pg_dumpall -U infisical > "$BACKUP_DIR/infisical.sql.tmp"
        mv "$BACKUP_DIR/infisical.sql.tmp" "$BACKUP_DIR/infisical.sql"
      '';
    })
  ]
