{
  config,
  myvars,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.seafile;
  domain = config.environment.variables.SEAFILE_DOMAIN;
in {
  age.secrets.seafile-db-password = {
    file = "${mysecrets}/${hostname}/seafile-db-password.age";
    mode = "0400";
  };

  age.secrets.seafile-admin-password = {
    file = "${mysecrets}/${hostname}/seafile-admin-password.age";
    mode = "0400";
  };

  age.secrets.seafile-jwt-key = {
    file = "${mysecrets}/${hostname}/seafile-jwt-key.age";
    mode = "0400";
  };

  # Create Docker network for Seafile containers to communicate
  systemd.services.init-seafile-network = {
    description = "Create Docker network for Seafile";
    after = ["docker.service" "docker.socket"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${config.virtualisation.docker.package}/bin/docker network inspect seafile-net >/dev/null 2>&1 || \
      ${config.virtualisation.docker.package}/bin/docker network create seafile-net
    '';
  };

  # Ensure containers wait for network to be created
  systemd.services.docker-seafile-db = {
    after = ["init-seafile-network.service"];
    requires = ["init-seafile-network.service"];
  };
  systemd.services.docker-seafile-redis = {
    after = ["init-seafile-network.service"];
    requires = ["init-seafile-network.service"];
  };
  systemd.services.docker-seafile = {
    after = ["init-seafile-network.service"];
    requires = ["init-seafile-network.service"];
  };

  # Create env files for Seafile containers
  system.activationScripts.seafile-env = ''
    mkdir -p /var/lib/seafile

    # Database password
    DB_PASSWORD=$(cat ${config.age.secrets.seafile-db-password.path})

    # Admin password
    ADMIN_PASSWORD=$(cat ${config.age.secrets.seafile-admin-password.path})

    # JWT key
    JWT_KEY=$(cat ${config.age.secrets.seafile-jwt-key.path})

    # MariaDB env file
    echo "MYSQL_ROOT_PASSWORD=$DB_PASSWORD" > /var/lib/seafile/db.env
    echo "MYSQL_LOG_CONSOLE=true" >> /var/lib/seafile/db.env
    echo "MARIADB_AUTO_UPGRADE=1" >> /var/lib/seafile/db.env
    chmod 600 /var/lib/seafile/db.env

    # Create MySQL init script for seafile user
    mkdir -p /srv/seafile/mysql-init
    cat > /srv/seafile/mysql-init/init-seafile-user.sql << EOF
    -- Create seafile user and grant permissions
    CREATE USER IF NOT EXISTS 'seafile'@'%' IDENTIFIED BY '$DB_PASSWORD';
    GRANT ALL PRIVILEGES ON ccnet_db.* TO 'seafile'@'%';
    GRANT ALL PRIVILEGES ON seafile_db.* TO 'seafile'@'%';
    GRANT ALL PRIVILEGES ON seahub_db.* TO 'seafile'@'%';
    FLUSH PRIVILEGES;
    EOF
    chmod 644 /srv/seafile/mysql-init/init-seafile-user.sql

    # Seafile env file (v13.0 format - matches official compose)
    cat > /var/lib/seafile/seafile.env << EOF
    # Server Configuration
    SEAFILE_SERVER_HOSTNAME=${domain}
    SEAFILE_SERVER_PROTOCOL=https
    TIME_ZONE=${myvars.timezone}
    SITE_ROOT=/
    NON_ROOT=false
    SEAFILE_LOG_TO_STDOUT=false

    # Admin Configuration (only used on first setup)
    INIT_SEAFILE_ADMIN_EMAIL=${myvars.userEmail}
    INIT_SEAFILE_ADMIN_PASSWORD=$ADMIN_PASSWORD

    # MySQL/MariaDB Configuration
    SEAFILE_MYSQL_DB_HOST=seafile-db
    SEAFILE_MYSQL_DB_PORT=3306
    SEAFILE_MYSQL_DB_USER=seafile
    SEAFILE_MYSQL_DB_PASSWORD=$DB_PASSWORD
    INIT_SEAFILE_MYSQL_ROOT_PASSWORD=$DB_PASSWORD
    SEAFILE_MYSQL_DB_CCNET_DB_NAME=ccnet_db
    SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db
    SEAFILE_MYSQL_DB_SEAHUB_DB_NAME=seahub_db

    # JWT Configuration
    JWT_PRIVATE_KEY=$JWT_KEY

    # Cache Configuration (Redis)
    CACHE_PROVIDER=redis
    REDIS_HOST=seafile-redis
    REDIS_PORT=6379
    REDIS_PASSWORD=

    # Notification Server
    ENABLE_NOTIFICATION_SERVER=true
    INNER_NOTIFICATION_SERVER_URL=http://notification-server:8083
    NOTIFICATION_SERVER_URL=https://${domain}/notification

    # SeaDoc Configuration (disabled - not running seadoc container)
    ENABLE_SEADOC=false

    # Seafile AI (disabled)
    ENABLE_SEAFILE_AI=false

    # Limits
    MD_FILE_COUNT_LIMIT=100000
    EOF
    chmod 600 /var/lib/seafile/seafile.env

    # Create custom seahub settings to append
    mkdir -p /srv/seafile
    cat > /srv/seafile/custom_settings.py << EOF
    # Custom settings for reverse proxy
    SERVICE_URL = "https://${domain}"
    FILE_SERVER_ROOT = "https://${domain}/seafhttp"
    ALLOWED_HOSTS = ['${domain}']
    CSRF_COOKIE_SECURE = True
    CSRF_COOKIE_SAMESITE = 'Strict'
    CSRF_TRUSTED_ORIGINS = ['https://${domain}']
    EOF
    chmod 644 /srv/seafile/custom_settings.py
  '';

  # MariaDB container
  virtualisation.oci-containers.containers.seafile-db = {
    image = "mariadb:10.11";
    autoStart = true;
    volumes = [
      "/srv/seafile/db:/var/lib/mysql"
      "/srv/seafile/mysql-init:/docker-entrypoint-initdb.d:ro"
    ];
    extraOptions = [
      "--network=seafile-net"
      "--health-cmd=healthcheck.sh --connect --mariadbupgrade --innodb_initialized"
      "--health-interval=20s"
      "--health-start-period=30s"
      "--health-timeout=5s"
      "--health-retries=10"
    ];
    environmentFiles = ["/var/lib/seafile/db.env"];
  };

  # Redis container (replaces Memcached in v13.0)
  virtualisation.oci-containers.containers.seafile-redis = {
    image = "redis:7-alpine";
    autoStart = true;
    extraOptions = [
      "--network=seafile-net"
    ];
  };

  # Seafile main container
  virtualisation.oci-containers.containers.seafile = {
    image = "seafileltd/seafile-mc:13.0-latest";
    autoStart = true;
    dependsOn = ["seafile-db" "seafile-redis"];
    volumes = [
      "/srv/seafile/data:/shared"
    ];
    ports = ["127.0.0.1:${toString port}:80"];
    extraOptions = [
      "--network=seafile-net"
    ];
    environmentFiles = ["/var/lib/seafile/seafile.env"];
  };

  services.traefik.dynamicConfigOptions.http = {
    services.seafile.loadBalancer.servers = [
      {
        url = "http://127.0.0.1:${toString port}";
      }
    ];

    routers.seafile = {
      rule = "Host(`${domain}`)";
      tls.certResolver = "letsencrypt";
      service = "seafile";
      entrypoints = "websecure";
    };
  };
}
