{
  config,
  mylib,
  myvars,
  ...
}: let
  port = config.ports.adguard;
in {
  systemd.tmpfiles.rules = [
    "d /srv/adguard 0700 adguardhome adguardhome -"
  ];

  fileSystems."/var/lib/private/AdGuardHome" = {
    device = "/srv/adguard";
    fsType = "none";
    options = ["bind"];
  };

  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    # Management stays behind the existing HTTPS proxy; DNS has separate listeners below.
    openFirewall = false;
    host = "127.0.0.1";
    inherit port;

    settings = {
      http.address = "127.0.0.1:${toString port}";
      users = [
        {
          name = myvars.usernameFull;
          password = "$2a$10$MTVeK29as5DfP4GgpZ1IZ.XvxXYQHw2juCnIiE8JPBAu/QQrZ/wz."; # bcrypt hashed
        }
      ];

      dns = {
        bind_hosts = ["0.0.0.0"];
        port = 53;
        upstream_dns = [
          # Mullvad internal DNS
          "10.64.0.1"
        ];
        bootstrap_dns = [
          # Mullvad internal DNS
          "10.64.0.1"
        ];
      };

      tls = {
        enabled = false; # Traefik handles TLS
      };

      querylog = {
        enabled = true;
        file_enabled = true;
        interval = "1d";
      };

      statistics = {
        interval = "1d";
        enabled = true;
      };

      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_51.txt";
          name = "HaGeZi's Pro++ Blocklist";
          id = 3;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_45.txt";
          name = "HaGeZi's Allowlist Referral";
          id = 4;
        }
        {
          enabled = true;
          url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.medium.txt";
          name = "HaGeZi's Threat Intelligence Feeds Medium";
          id = 5;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt";
          name = "Phishing Army";
          id = 6;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/fmhy/FMHYFilterlist/main/filterlist-abp.txt";
          name = "FMHY Filterlist";
          id = 7;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/LegitimateURLShortener.txt";
          name = "Legitimate URL Shortener";
          id = 8;
        }
      ];

      filtering = {
        filtering_enabled = true;
        protection_enabled = true;
        rewrites = [
          {
            domain = "*.shupi.ushira.com";
            answer = "100.74.32.50";
            enabled = false; # Preserve the current mutable rewrite state during management hardening.
          }
        ];
      };
    };
  };

  networking.firewall = {
    # Keep existing LAN and container consumers; tailnet ingress uses its existing trusted interface.
    extraInputRules = ''
      iifname "end0" ip saddr 192.168.1.0/24 tcp dport 53 accept
      iifname "end0" ip saddr 192.168.1.0/24 udp dport 53 accept
      iifname "docker0" tcp dport 53 accept
      iifname "docker0" udp dport 53 accept
      iifname "br-*" tcp dport 53 accept
      iifname "br-*" udp dport 53 accept
    '';
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "adguard";
    domain = config.environment.variables.ADGUARD_DOMAIN;
    host = "127.0.0.1";
    inherit port;
  };
}
