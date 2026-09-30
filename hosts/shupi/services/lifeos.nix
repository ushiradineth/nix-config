{pkgs, ...}: let
  observer = pkgs.writeText "lifeos-observer.py" (builtins.readFile ./lifeos-observer.py);
in {
  services.traefik.dynamicConfigOptions.http = {
    routers.lifeos = {
      rule = "Host(`lifeos.shupi.ushira.com`)";
      entryPoints = ["websecure"];
      service = "lifeos";
      middlewares = ["lifeos-tailnet-only"];
      tls.certResolver = "letsencrypt";
    };
    # Match the actual peer address. Do not trust client-supplied forwarding headers.
    middlewares.lifeos-tailnet-only.ipAllowList.sourceRange = [
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
    ];
    services.lifeos.loadBalancer.servers = [{url = "http://127.0.0.1:4311";}];
  };

  systemd.services.lifeos = {
    description = "LifeOS private dashboard";
    wantedBy = ["multi-user.target"];
    after = ["docker.service" "tailscaled.service" "network-online.target"];
    requires = ["docker.service"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/home/shu/lifeos";
      ExecStart = "${pkgs.docker}/bin/docker compose up -d --no-build";
      ExecStop = "${pkgs.docker}/bin/docker compose stop";
      TimeoutStartSec = 180;
    };
  };

  systemd.services.lifeos-observer = {
    description = "Collect bounded read-only LifeOS operational summaries";
    environment = {
      SYSTEMCTL = "${pkgs.systemd}/bin/systemctl";
      JOURNALCTL = "${pkgs.systemd}/bin/journalctl";
    };
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "lifeos-observer";
      ExecStart = "${pkgs.python3}/bin/python ${observer}";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };
  systemd.timers.lifeos-observer = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "15min";
    };
  };
  systemd.services.lifeos-activity = {
    description = "Collect read-only LifeOS coding and public commit summaries";
    after = ["network-online.target" "wakapi.service"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "shu";
      StateDirectory = "lifeos-activity";
      StateDirectoryMode = "0755";
      ExecStart = "${pkgs.python3}/bin/python /home/shu/lifeos/scripts/collect-activity.py";
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      PrivateTmp = true;
      NoNewPrivileges = true;
      TimeoutStartSec = 90;
    };
  };
  systemd.timers.lifeos-activity = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "15min";
    };
  };
  systemd.services.lifeos-db-dump = {
    description = "Dump LifeOS PostgreSQL into the existing database backup tier";
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/home/shu/lifeos";
      UMask = "0077";
    };
    script = ''
      ${pkgs.docker}/bin/docker compose exec -T postgres pg_dump -U lifeos -d lifeos -Fc > /var/backup/databases/lifeos.dump.tmp
      ${pkgs.coreutils}/bin/mv /var/backup/databases/lifeos.dump.tmp /var/backup/databases/lifeos.dump
    '';
  };
  systemd.timers.lifeos-db-dump = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 01:45:00";
      Persistent = true;
    };
  };
}
