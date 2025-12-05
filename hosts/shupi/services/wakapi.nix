{
  config,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.wakapi;
  domain = config.environment.variables.WAKAPI_DOMAIN;
in {
  age.secrets.wakapi-password-salt = {
    file = "${mysecrets}/${hostname}/wakapi-password-salt.age";
    mode = "0400";
  };

  services.wakapi = {
    enable = true;
    passwordSaltFile = config.age.secrets.wakapi-password-salt.path;
    settings = {
      server = {
        port = port;
        listen_ipv4 = "127.0.0.1";
        base_path = "/";
        public_url = "https://${domain}";
      };
      app = {
        aggregation_time = "02:15";
        report_time_weekly = "fri,18:00";
        data_retention_months = -1;
        max_inactive_months = 12;
        import_batch_size = 50;
        inactive_days = 7;
      };
    };
  };
}
