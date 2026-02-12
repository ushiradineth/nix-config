{
  config,
  hostname,
  mysecrets,
  mylib,
  ...
}: let
  port = config.ports.linkding;
in {
  age.secrets.linkding-superuser-name = {
    file = "${mysecrets}/${hostname}/linkding-superuser-name.age";
    mode = "0400";
  };

  age.secrets.linkding-superuser-password = {
    file = "${mysecrets}/${hostname}/linkding-superuser-password.age";
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d /srv/linkding 0755 root root -"
    "d /var/lib/linkding 0700 root root -"
  ];

  system.activationScripts.linkding-env = ''
    USERNAME=$(cat ${config.age.secrets.linkding-superuser-name.path} | tr -d '[:space:]')
    PASSWORD=$(cat ${config.age.secrets.linkding-superuser-password.path} | tr -d '[:space:]')

    {
      printf 'LD_SUPERUSER_NAME=%s\n' "$USERNAME"
      printf 'LD_SUPERUSER_PASSWORD=%s\n' "$PASSWORD"
      printf 'LD_DB_ENGINE=sqlite\n'
    } > /var/lib/linkding/linkding.env

    chmod 600 /var/lib/linkding/linkding.env
  '';

  virtualisation.oci-containers.containers.linkding = {
    image = "sissbruecker/linkding:1.42.0";
    autoStart = true;
    ports = ["127.0.0.1:${toString port}:9090"];
    volumes = ["/srv/linkding:/etc/linkding/data"];
    environmentFiles = ["/var/lib/linkding/linkding.env"];
    extraOptions = [
      "--health-cmd=wget -qO- http://localhost:9090/health || exit 1"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=5"
      "--health-start-period=30s"
    ];
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "linkding";
    domain = config.environment.variables.LINKDING_DOMAIN;
    inherit port;
  };
}
