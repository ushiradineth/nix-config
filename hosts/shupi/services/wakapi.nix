{
  config,
  pkgs,
  lib,
  mylib,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.wakapi;
  domain = config.environment.variables.WAKAPI_DOMAIN;
  emailDomain = config.environment.variables.EMAIL_DOMAIN;
  smtpHost = config.environment.variables.SMTP_HOST;
  smtpPort = config.environment.variables.SMTP_PORT;
  smtpUser = config.environment.variables.SMTP_USER;
in
  lib.mkMerge [
    {
      age.secrets.wakapi-password-salt = {
        file = "${mysecrets}/${hostname}/wakapi-password-salt.age";
        mode = "0400";
      };

      age.secrets.resend-api-key = {
        file = "${mysecrets}/${hostname}/resend-api-key.age";
        mode = "0400";
      };

      system.activationScripts.wakapi-env-files = ''
        mkdir -p /var/lib/wakapi

        PASS_SALT=$(cat ${config.age.secrets.wakapi-password-salt.path} | tr -d '[:space:]')
        SMTP_PASS=$(cat ${config.age.secrets.resend-api-key.path} | tr -d '[:space:]')

        echo "WAKAPI_PASSWORD_SALT=$PASS_SALT" > /var/lib/wakapi/password-salt.env
        echo "WAKAPI_MAIL_SMTP_PASS=$SMTP_PASS" > /var/lib/wakapi/smtp.env

        chmod 600 /var/lib/wakapi/*.env
      '';

      services.wakapi = {
        enable = true;
        stateDir = "/srv/wakapi";
        passwordSaltFile = "/var/lib/wakapi/password-salt.env";
        smtpPasswordFile = "/var/lib/wakapi/smtp.env";
        database = {
          createLocally = true;
          dialect = "postgres";
          name = "wakapi";
          user = "wakapi";
        };
        settings = {
          server = {
            port = port;
            listen_ipv4 = "127.0.0.1";
            base_path = "/";
            public_url = "https://${domain}";
          };
          app = {
            leaderboard_enabled = false;
            aggregation_time = "0 15 2 * * *"; # daily 02:15
            report_time_weekly = "0 0 9 * * 1"; # Monday 09:00
            data_cleanup_time = "0 0 6 * * 0"; # Sunday 06:00
            optimize_database_time = "0 0 8 1 * *"; # 1st of month 08:00
            import_enabled = true;
            import_backoff_min = 5;
            import_max_rate = 24;
            import_batch_size = 50;
            heartbeat_max_age = "4320h";
            data_retention_months = -1;
            max_inactive_months = 12;
            inactive_days = 7;
            warm_caches = true;
          };
          mail = {
            enabled = true;
            provider = "smtp";
            sender = "Wakapi <wakapi@${emailDomain}>";
            skip_verify_mx_record = false;
            smtp = {
              host = smtpHost;
              port = lib.toInt smtpPort;
              username = smtpUser;
              tls = false;
            };
          };
          db = {
            dialect = "postgres";
            user = "wakapi";
            name = "wakapi";
            host = "127.0.0.1";
            port = 5432;
          };
        };
      };
    }

    (mylib.dockerHelpers.mkDatabaseDumpService {
      inherit config pkgs;
      name = "wakapi";
      description = "Dump Wakapi PostgreSQL database";
      dumpCommand = ''
        ${pkgs.util-linux}/bin/runuser -u postgres -- ${pkgs.postgresql}/bin/pg_dump wakapi > "$BACKUP_DIR/wakapi.sql.tmp"
        mv "$BACKUP_DIR/wakapi.sql.tmp" "$BACKUP_DIR/wakapi.sql"
      '';
    })
  ]
