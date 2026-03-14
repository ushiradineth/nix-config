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
    block_when_disconnected = true;

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
        location.only.location.country = "sg";
        openvpn_constraints.port = "any";
        ownership = "any";
        providers = "any";
        tunnel_protocol = "wireguard";
        wireguard_constraints = {
          ip_version = "any";
          port = "any";
          use_multihop = false;
          entry_location.only.location.country = "sg";
        };
      };
    };

    obfuscation_settings = {
      selected_obfuscation = "auto";
      udp2tcp.port = "any";
    };

    tunnel_options = {
      openvpn.mssfix = null;
      generic.enable_ipv6 = false;
      wireguard = {
        mtu = null;
        quantum_resistant = "on";
        rotation_interval = null;
        daita = {
          enabled = true;
          use_multihop_if_necessary = false;
        };
      };
      dns_options = {
        state = "default";
        default_options = {
          block_ads = true;
          block_trackers = true;
          block_malware = true;
          block_adult_content = true;
          block_gambling = true;
          block_social_media = true;
        };
        custom_options.addresses = [];
      };
    };

    settings_version = 12;
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
    services."mullvad-daemon".environment.MULLVAD_SETTINGS_DIR = "/var/lib/mullvad-vpn";

    services."mullvad-daemon".preStart = ''
      cp --no-preserve=all ${mullvadSettings} /var/lib/mullvad-vpn/settings.json
      chmod 600 /var/lib/mullvad-vpn/settings.json
    '';

    services."mullvad-daemon".postStart = let
      mullvad = config.services.mullvad-vpn.package;
    in ''
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

      ${mullvad}/bin/mullvad lan set allow
      ${mullvad}/bin/mullvad connect
    '';
  };
}
