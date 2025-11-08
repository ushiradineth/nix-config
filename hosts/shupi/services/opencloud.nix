{
  config,
  hostname,
  mysecrets,
  myvars,
  ...
}: let
  port = config.ports.opencloud;
in {
  age.secrets.oc-initial-admin-password = {
    file = "${mysecrets}/${hostname}/oc-initial-admin-password.age";
    mode = "0500";
    owner = myvars.username;
  };

  virtualisation.oci-containers.containers.opencloud = {
    image = "opencloudeu/opencloud-rolling:latest";
    autoStart = true;
    ports = ["127.0.0.1:${toString port}:9200"];
    entrypoint = "/bin/sh";
    cmd = [
      "-c"
      ''
        export IDM_ADMIN_PASSWORD=$(cat /run/secrets/initial-admin-password)
        opencloud server
      ''
    ];
    volumes = [
      "/srv/opencloud/config:/etc/opencloud"
      "/srv/opencloud/data:/var/lib/opencloud"
      "${config.age.secrets.oc-initial-admin-password.path}:/run/secrets/initial-admin-password:ro"
    ];
    environment = {
      OC_URL = "https://${config.environment.variables.OC_DOMAIN}";
      PROXY_TLS = "false";
      OC_INSECURE = "false";
      PROXY_ENABLE_BASIC_AUTH = "false";
      TZ = myvars.timezone;
      NO_PROXY = "127.0.0.1,localhost,${config.environment.variables.OC_DOMAIN}";
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    services.opencloud.loadBalancer.servers = [
      {
        url = "http://localhost:${toString port}";
      }
    ];

    routers.opencloud = {
      rule = "Host(`${config.environment.variables.OC_DOMAIN}`)";
      tls.certResolver = "letsencrypt";
      service = "opencloud";
      entrypoints = "websecure";
    };
  };
}
