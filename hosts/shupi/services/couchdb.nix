{
  config,
  pkgs,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.couchdb;
  domain = config.environment.variables.COUCHDB_DOMAIN;
in {
  age.secrets.couchdb-admin-password = {
    file = "${mysecrets}/${hostname}/couchdb-admin-password.age";
    mode = "0400";
  };

  # Create env file for CouchDB container
  system.activationScripts.couchdb-env = ''
        mkdir -p /var/lib/couchdb
        mkdir -p /srv/couchdb/data
        mkdir -p /srv/couchdb/config

        # Read admin password from age secret
        ADMIN_PASSWORD=$(cat ${config.age.secrets.couchdb-admin-password.path})

        # Create CouchDB env file
        echo "COUCHDB_USER=admin" > /var/lib/couchdb/couchdb.env
        echo "COUCHDB_PASSWORD=$ADMIN_PASSWORD" >> /var/lib/couchdb/couchdb.env
        chmod 600 /var/lib/couchdb/couchdb.env

        # Create CouchDB local.ini for CORS configuration
        cat > /srv/couchdb/config/local.ini << 'EOF'
    [chttpd]
    require_valid_user = true
    max_http_request_size = 4294967296

    [httpd]
    enable_cors = true
    WWW-Authenticate = Basic realm="couchdb"

    [cors]
    origins = app://obsidian.md,capacitor://localhost,http://localhost
    credentials = true
    headers = accept, authorization, content-type, origin, referer
    methods = GET, PUT, POST, HEAD, DELETE
    EOF
        chmod 644 /srv/couchdb/config/local.ini
  '';

  # CouchDB container
  virtualisation.oci-containers.containers.couchdb = {
    image = "couchdb:3.3.3";
    autoStart = true;
    volumes = [
      "/srv/couchdb/data:/opt/couchdb/data"
      "/srv/couchdb/config:/opt/couchdb/etc/local.d"
    ];
    ports = ["127.0.0.1:${toString port}:5984"];
    extraOptions = [
      "--health-cmd=curl -f http://localhost:5984/_up || exit 1"
      "--health-interval=30s"
      "--health-start-period=10s"
      "--health-timeout=5s"
      "--health-retries=3"
    ];
    environmentFiles = ["/var/lib/couchdb/couchdb.env"];
  };

  # Traefik routing for CouchDB
  services.traefik.dynamicConfigOptions.http = {
    services.couchdb.loadBalancer.servers = [{url = "http://localhost:${toString port}";}];
    routers.couchdb = {
      rule = "Host(`${domain}`)";
      tls.certResolver = "letsencrypt";
      service = "couchdb";
      entrypoints = "websecure";
    };
  };

  # NOTE: CouchDB backup uses file-based approach (already in TIER 2)
  # Backing up /srv/couchdb/data directly is more reliable than REST API dumps
  # See: https://docs.couchdb.org/en/stable/maintenance/backups.html
}
