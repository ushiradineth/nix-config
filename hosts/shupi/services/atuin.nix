{
  config,
  lib,
  mylib,
  pkgs,
  ...
}: let
  port = config.ports.atuin;
  domain = config.environment.variables.ATUIN_DOMAIN;
  route = mylib.traefikHelpers.mkTraefikRoute {
    name = "atuin";
    host = "127.0.0.1";
    inherit domain port;
  };
in
  lib.mkMerge [
    {
      services.atuin = {
        enable = true;
        host = "127.0.0.1";
        inherit port;
        openFirewall = false;
        openRegistration = false;
        database.createLocally = true;
      };

      services.traefik.dynamicConfigOptions.http = lib.recursiveUpdate route {
        middlewares.atuin-tailnet.ipAllowList.sourceRange = ["100.64.0.0/10"];
        routers.atuin.middlewares = ["atuin-tailnet"];
      };

      systemd.services.dump-atuin-db = {
        after = ["postgresql.service"];
        requires = ["postgresql.service"];
      };
    }

    (mylib.dockerHelpers.mkDatabaseDumpService {
      inherit config pkgs;
      name = "atuin";
      description = "Dump Atuin PostgreSQL database";
      dumpCommand = ''
        ${pkgs.util-linux}/bin/runuser -u postgres -- ${config.services.postgresql.package}/bin/pg_dump -Fc atuin > "$BACKUP_DIR/atuin.dump.tmp"
        mv "$BACKUP_DIR/atuin.dump.tmp" "$BACKUP_DIR/atuin.dump"
      '';
    })
  ]
