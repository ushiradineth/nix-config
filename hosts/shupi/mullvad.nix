{
  pkgs,
  mysecrets,
  hostname,
  config,
  ...
}: let
  mullvadSettings = pkgs.writeText "mullvad-settings.json" (builtins.toJSON {
    allow_lan = true;
    auto_connect = true;
    block_when_disconnected = true; # Kill switch - blocks internet if VPN disconnects

    api_access_methods = {
      custom = [];
      direct = {
        access_method.built_in = "direct";
        enabled = true;
        id = "00000000-0000-0000-0000-000000000008";
        name = "Direct";
      };
      mullvad_bridges = {
        access_method.built_in = "bridge";
        enabled = true;
        id = "00000000-0000-0000-0000-000000000009";
        name = "Mullvad Bridges";
      };
      encrypted_dns_proxy = {
        access_method.built_in = "encrypted_dns_proxy";
        enabled = true;
        id = "00000000-0000-0000-0000-000000000010";
        name = "Encrypted DNS proxy";
      };
    };

    bridge_state = "auto";
    bridge_settings = {
      bridge_type = "normal";
      custom = null;
      normal = {
        location = "any";
        ownership = "any";
        providers = "any";
      };
    };

    relay_overrides = [];

    relay_settings = {
      normal = {
        location = {
          only = {
            location = {
              country = "sg";
              city = "sin";
              hostname = "sg-sin-wg-001";
            };
          };
        };
        openvpn_constraints.port = "any";
        ownership = "any";
        providers = "any";
        tunnel_protocol = "wireguard";
        wireguard_constraints = {
          ip_version = "any";
          port = "any";
          use_multihop = false;
        };
      };
    };

    obfuscation_settings = {
      selected_obfuscation = "auto";
      udp2tcp.port = "any";
    };

    tunnel_options = {
      openvpn.mssfix = null;
      generic.enable_ipv6 = true;
      wireguard = {
        mtu = null;
        quantum_resistant = "auto";
        rotation_interval = null;
        daita = {
          enabled = true;
          use_multihop_if_necessary = false;
        };
      };
      # Adguard points to Mullvad's DNS but filtering occurs on the Adguard layer
      dns_options = {
        state = "default";
        default_options = {
          block_ads = false;
          block_trackers = false;
          block_malware = false;
          block_adult_content = false;
          block_gambling = false;
          block_social_media = false;
        };
      };
    };

    settings_version = 10;
    show_beta_releases = false;
  });
in {
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  environment.systemPackages = with pkgs; [
    mullvad
    mullvad-vpn
  ];

  age.secrets.mullvad-account-id.file = "${mysecrets}/${hostname}/mullvad-account-id.age";

  systemd = {
    # Set writable settings directory
    services."mullvad-daemon".environment.MULLVAD_SETTINGS_DIR = "/var/lib/mullvad-vpn";

    # Copy declarative settings to Mullvad directory
    tmpfiles.settings."10-mullvad-settings"."/var/lib/mullvad-vpn/settings.json"."C+" = {
      group = "root";
      mode = "0700";
      user = "root";
      argument = "${mullvadSettings}";
    };

    # Ensure Mullvad starts after Tailscale
    services."mullvad-daemon" = {
      after = ["tailscaled.service"];
      wants = ["tailscaled.service"];
      postStart = let
        mullvad = config.services.mullvad-vpn.package;
      in ''
        # Wait for daemon to be ready
        while ! ${mullvad}/bin/mullvad status >/dev/null 2>&1; do
          sleep 1
        done

        if ${mullvad}/bin/mullvad account get 2>&1 | grep -qi "Not logged in"; then
          echo "Logging in to Mullvad..."
          ACCOUNT_ID=$(cat ${config.age.secrets.mullvad-account-id.path} | tr -d '[:space:]')
          ${mullvad}/bin/mullvad account login "$ACCOUNT_ID"
        else
          echo "Already logged in to Mullvad"
        fi

        # Enable LAN access (required for local network + Tailscale)
        ${mullvad}/bin/mullvad lan set allow
      '';
    };

    # Ensure Tailscale CGNAT range routes through tailscale0, not Mullvad
    services.tailscale-route-fix = {
      description = "Fix Tailscale routing to prevent Mullvad hijacking";
      after = ["tailscaled.service" "mullvad-daemon.service"];
      wants = ["tailscaled.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/ip route add 100.64.0.0/10 dev tailscale0";
        ExecStartPost = "${pkgs.coreutils}/bin/sleep 1";
        # Ignore errors if route already exists
        SuccessExitStatus = "0 2";
      };
    };
  };

  # nftables rules for Tailscale + Mullvad coexistence
  # Marks: 0x00000f41 (ct mark) + 0x6d6f6c65 (meta mark = "mole") = bypass Mullvad tunnel
  networking.nftables.tables.mullvad-tailscale = {
    family = "inet";
    content = ''
      chain output {
        type route hook output priority dstnat; policy accept;
        # Mark locally-generated traffic TO Tailscale peers (CGNAT range) to bypass Mullvad
        ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65
      }
    '';
  };

  # NAT rules for Tailscale exit node traffic through Mullvad
  networking.nftables.tables.tailscale-exit-nat = {
    family = "ip";
    content = ''
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        # Masquerade exit node traffic from Tailscale going through Mullvad
        iifname "tailscale0" oifname "wg0-mullvad" masquerade
      }
    '';
  };
}
