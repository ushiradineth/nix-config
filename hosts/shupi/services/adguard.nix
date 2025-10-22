{config, ...}: {
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    openFirewall = true;
    host = "0.0.0.0";
    port = 48005;

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
          "https://dns10.quad9.net/dns-query"
        ];
        bootstrap_dns = [
          "9.9.9.10"
          "149.112.112.10"
          "2620:fe::10"
          "2620:fe::fe:10"
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
          id = 1758608610;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_45.txt";
          name = "HaGeZi's Allowlist Referral";
          id = 1758608611;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt";
          name = "HaGeZi's Threat Intelligence Feeds";
          id = 1758826497;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt";
          name = "Phishing Army";
          id = 1758826499;
        }
      ];

      filtering = {
        filtering_enabled = true;
        protection_enabled = true;
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };

  services.traefik.dynamicConfigOptions.http = {
    services.adguard.loadBalancer.servers = [
      {
        url = "http://localhost:48005";
      }
    ];

    routers.adguard = {
      rule = "Host(`${config.environment.variables.ADGUARD_DOMAIN}`)";
      tls.certResolver = "letsencrypt";
      service = "adguard";
      entrypoints = "websecure";
    };
  };
}
