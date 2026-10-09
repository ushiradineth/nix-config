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
  sshDir = "/var/lib/paperclip/ssh";
  dockerSubnet = "172.17.0.0/16";
  workerHost = "100.120.236.115";
  sshConfig = pkgs.writeText "paperclip-ssh-config" ''
    Host shu
      HostName ${workerHost}
      User shu
      IdentityFile /etc/ssh/paperclip_id_ed25519
      IdentitiesOnly yes
      BatchMode yes
      StrictHostKeyChecking yes
      UserKnownHostsFile /etc/ssh/paperclip_known_hosts
      UpdateHostKeys no
  '';
  sshKnownHosts = pkgs.writeText "paperclip-ssh-known-hosts" ''
    ${workerHost} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKOesw4LmRS/uw1s9kTUmddcq2OMM25HV1oi+4A6IYWS
  '';
  route = mylib.traefikHelpers.mkTraefikRoute {
    name = "paperclip";
    host = "127.0.0.1";
    inherit domain port;
  };
in {
  systemd.tmpfiles.rules = [
    "d /srv/paperclip 0700 1000 1000 -"
    "d /var/lib/paperclip 0700 root root -"
    "d ${sshDir} 0700 1000 1000 -"
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

  systemd.services.paperclip-ssh-files = {
    description = "Prepare Paperclip SSH client files";
    path = [pkgs.coreutils];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
    script = ''
      set -euo pipefail

      test -s ${sshDir}/id_ed25519
      chown 1000:1000 ${sshDir}/id_ed25519 ${sshDir}/id_ed25519.pub
      chmod 0600 ${sshDir}/id_ed25519
      chmod 0644 ${sshDir}/id_ed25519.pub
      install -m 0644 -o 1000 -g 1000 ${sshConfig} ${sshDir}/config
      install -m 0644 -o 1000 -g 1000 ${sshKnownHosts} ${sshDir}/known_hosts
    '';
  };

  virtualisation.oci-containers.containers.paperclip = {
    image = "ghcr.io/paperclipai/paperclip:2026.1005.0@sha256:de762433b50d56ed9180fef96a13fa236b37856c5c7a7718e8f19afe3d1e8670";
    autoStart = true;
    ports = ["127.0.0.1:${toString port}:3100"];
    volumes = [
      "/srv/paperclip:/paperclip"
      "${sshDir}:/paperclip/.ssh:ro"
      "${sshDir}/config:/etc/ssh/ssh_config.d/99-paperclip.conf:ro"
      "${sshDir}/id_ed25519:/etc/ssh/paperclip_id_ed25519:ro"
      "${sshDir}/known_hosts:/etc/ssh/paperclip_known_hosts:ro"
    ];
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
      # Codex ACP creates a nested Bubblewrap sandbox. Docker's default seccomp
      # profile blocks its namespace syscalls; avoid granting CAP_SYS_ADMIN.
      "--security-opt=seccomp=unconfined"
      "--security-opt=no-new-privileges:true"
      "--health-cmd=node -e \"require('http').get('http://127.0.0.1:3100/api/health', r => r.statusCode === 200 ? process.exit(0) : process.exit(1)).on('error', () => process.exit(1))\""
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=5"
      "--health-start-period=90s"
    ];
  };

  systemd.services.docker-paperclip = {
    after = [
      "paperclip-secrets.service"
      "paperclip-ssh-files.service"
    ];
    requires = [
      "paperclip-secrets.service"
      "paperclip-ssh-files.service"
    ];
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
