{
  config,
  mylib,
  ...
}: let
  port = config.ports.adguard;
in {
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    openFirewall = true;
    host = "0.0.0.0";
    inherit port;

    settings = {
      users = [
        {
          name = "ushiradineth";
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
      };

      statistics = {
        interval = "24h";
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
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt";
          name = "HaGeZi's Threat Intelligence Feeds";
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
          }
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "adguard";
    domain = config.environment.variables.ADGUARD_DOMAIN;
    inherit port;
  };
}
