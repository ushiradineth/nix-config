{
  config,
  mylib,
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

  system.activationScripts.couchdb-env = ''
        mkdir -p /var/lib/couchdb
        mkdir -p /srv/couchdb/data
        mkdir -p /srv/couchdb/config

        ADMIN_PASSWORD=$(cat ${config.age.secrets.couchdb-admin-password.path})

        echo "COUCHDB_USER=admin" > /var/lib/couchdb/couchdb.env
        echo "COUCHDB_PASSWORD=$ADMIN_PASSWORD" >> /var/lib/couchdb/couchdb.env
        chmod 600 /var/lib/couchdb/couchdb.env

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

  virtualisation.oci-containers.containers.couchdb = {
    image = "couchdb:3.3.3";
    autoStart = true;
    volumes = [
      "/srv/couchdb/data:/opt/couchdb/data"
      "/srv/couchdb/config:/opt/couchdb/etc/local.d"
    ];
    ports = ["127.0.0.1:${toString port}:5984"];
    extraOptions = [
      "--health-cmd=sh -c 'curl -fsS -u \"$COUCHDB_USER:$COUCHDB_PASSWORD\" http://localhost:5984/_up || exit 1'"
      "--health-interval=30s"
      "--health-start-period=10s"
      "--health-timeout=5s"
      "--health-retries=3"
    ];
    environmentFiles = ["/var/lib/couchdb/couchdb.env"];
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "couchdb";
    domain = domain;
    port = port;
  };

  # File-based backup in TIER 2 (more reliable than REST API dumps)
}
