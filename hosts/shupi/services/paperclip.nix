{
  config,
  lib,
  mylib,
  pkgs,
  ...
}: let
  port = config.ports.paperclip;
  domain = config.environment.variables.PAPERCLIP_DOMAIN;
  envFile = "/var/lib/paperclip/paperclip.env";
  dockerSubnet = "172.17.0.0/16";
  workerHost = "100.120.236.115";
  route = mylib.traefikHelpers.mkTraefikRoute {
    name = "paperclip";
    host = "127.0.0.1";
    inherit domain port;
  };
in {
  systemd.tmpfiles.rules = [
    "d /srv/paperclip 0700 1000 1000 -"
    "d /var/lib/paperclip 0700 root root -"
  ];

  systemd.services.paperclip-secrets = {
    description = "Create persistent Paperclip deployment secrets";
    path = with pkgs; [coreutils openssl];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
    script = ''
      set -euo pipefail

      if [ -e ${envFile} ]; then
        exit 0
      fi

      temporary_file="$(mktemp /var/lib/paperclip/paperclip.env.XXXXXX)"
      trap 'rm -f "$temporary_file"' EXIT

      {
        printf 'BETTER_AUTH_SECRET=%s\n' "$(openssl rand -hex 32)"
        printf 'PAPERCLIP_TOOL_ACTION_SIGNING_SECRET=%s\n' "$(openssl rand -hex 32)"
      } > "$temporary_file"

      chown root:root "$temporary_file"
      chmod 0600 "$temporary_file"
      mv "$temporary_file" ${envFile}
      trap - EXIT
    '';
  };

  virtualisation.oci-containers.containers.paperclip = {
    image = "ghcr.io/paperclipai/paperclip:2026.1005.0@sha256:de762433b50d56ed9180fef96a13fa236b37856c5c7a7718e8f19afe3d1e8670";
    autoStart = true;
    ports = ["127.0.0.1:${toString port}:3100"];
    volumes = ["/srv/paperclip:/paperclip"];
    environment = {
      PAPERCLIP_DEPLOYMENT_MODE = "authenticated";
      PAPERCLIP_DEPLOYMENT_EXPOSURE = "private";
      # Keep controller-internal MCP callbacks off the tailnet-only public route.
      PAPERCLIP_API_URL = "http://127.0.0.1:3100";
      PAPERCLIP_PUBLIC_URL = "https://${domain}";
      PAPERCLIP_ALLOWED_HOSTNAMES = domain;
      PAPERCLIP_TELEMETRY_DISABLED = "1";
    };
    environmentFiles = [envFile];
    extraOptions = [
      "--pids-limit=2048"
      "--health-cmd=node -e \"require('http').get('http://127.0.0.1:3100/api/health', r => r.statusCode === 200 ? process.exit(0) : process.exit(1)).on('error', () => process.exit(1))\""
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=5"
      "--health-start-period=90s"
    ];
  };

  systemd.services.docker-paperclip = {
    after = ["paperclip-secrets.service"];
    requires = ["paperclip-secrets.service"];
  };

  systemd.services.paperclip-backup = {
    description = "Create a logical Paperclip database backup";
    after = ["docker-paperclip.service"];
    requires = ["docker-paperclip.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.virtualisation.docker.package}/bin/docker exec --user node paperclip pnpm paperclipai db:backup";
    };
  };

  systemd.timers.paperclip-backup = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };

  networking.nftables.tables.paperclip-worker-ssh-nat = {
    family = "ip";
    content = ''
      chain prerouting {
        type filter hook prerouting priority mangle; policy accept;
        iifname "docker0" ip saddr ${dockerSubnet} ip daddr ${workerHost} tcp dport 22 ct mark set 0x00000f41 meta mark set 0x6d6f6c65
      }

      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        ip saddr ${dockerSubnet} ip daddr ${workerHost} tcp dport 22 oifname "tailscale0" masquerade
      }
    '';
  };

  services.traefik.dynamicConfigOptions.http = lib.recursiveUpdate route {
    middlewares.paperclip-tailnet-only.ipAllowList.sourceRange = [
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
    ];
    routers.paperclip.middlewares = ["paperclip-tailnet-only"];
  };
}
