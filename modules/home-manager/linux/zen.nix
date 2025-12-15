{
  pkgs,
  zen-browser,
  ...
}: {
  programs.zen-browser = {
    enable = true;
    package = zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default.override {
      nativeMessagingHosts = [pkgs.firefoxpwa];
    };

    policies = let
      mkLockedAttrs = builtins.mapAttrs (_: value: {
        Value = value;
        Status = "locked";
      });

      mkPluginUrl = id: "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";

      mkExtensionEntry = {
        id,
        pinned ? false,
      }: let
        base = {
          install_url = mkPluginUrl id;
          installation_mode = "force_installed";
        };
      in
        if pinned
        then base // {default_area = "navbar";}
        else base;

      mkExtensionSettings = builtins.mapAttrs (_: entry:
        if builtins.isAttrs entry
        then entry
        else mkExtensionEntry {id = entry;});
    in {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      SanitizeOnShutdown = {
        FormData = true;
        Cache = true;
      };
      ExtensionSettings = mkExtensionSettings {
        "ublock0@raymondhill.net" = mkExtensionEntry {
          id = "ublock-origin";
          pinned = true;
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkExtensionEntry {
          id = "bitwarden-password-manager";
          pinned = true;
        };
        "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = "refined-github-";
      };
      Preferences = mkLockedAttrs {
        "browser.aboutConfig.showWarning" = false;
        "browser.tabs.warnOnClose" = false;
        "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;
        "browser.tabs.hoverPreview.enabled" = true;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.topsites.contile.enabled" = false;
        "browser.newtabpage.activity-stream.trendingSearch.defaultSearchEngine" = "DuckDuckGo";
        "browser.search.separatePrivateDefault" = false;

        "privacy.resistFingerprinting" = true;
        "privacy.resistFingerprinting.randomization.canvas.use_siphash" = true;
        "privacy.resistFingerprinting.randomization.daily_reset.enabled" = true;
        "privacy.resistFingerprinting.randomization.daily_reset.private.enabled" = true;
        "privacy.resistFingerprinting.block_mozAddonManager" = true;
        "privacy.spoof_english" = 1;

        "privacy.firstparty.isolate" = true;
        "network.cookie.cookieBehavior" = 5;
        "dom.battery.enabled" = false;

        "gfx.webrender.all" = true;
        "network.http.http3.enabled" = true;
        "network.socket.ip_addr_any.disabled" = true; # disallow bind to 0.0.0.0
      };
    };

    profiles.default = rec {
      settings = {
        "zen.welcome-screen.seen" = true;
        "zen.workspaces.natural-scroll" = true;
        "zen.view.compact.hide-tabbar" = true;
        "zen.view.compact.hide-toolbar" = true;
        "zen.view.use-single-toolbar" = false;
        "zen.view.compact.animate-sidebar" = false;
        "zen.workspaces.continue-where-left-off" = true;
      };

      containersForce = true;
      containers = {
        Personal = {
          color = "blue";
          icon = "fingerprint";
          id = 1;
        };
      };

      spacesForce = true;
      spaces = {
        "Personal" = {
          id = "57dcd423-2d4c-4838-b24a-2fd337a1c985";
          icon = "🧋";
          position = 1000;
        };
      };

      pinsForce = true;
      pins = {
        "Gmail" = {
          id = "5065293b-1c04-40ee-ba1d-99a231873864";
          url = "https://mail.google.com/mail/u/1/#inbox";
          position = 101;
          isEssential = true;
        };
        "Google Drive" = {
          id = "7bcf9e17-e86e-4d98-bca1-599d8b34a047";
          url = "https://drive.google.com/drive/u/1/my-drive";
          position = 102;
          isEssential = true;
        };
        "YouTube" = {
          id = "4c99ba9f-4689-4b3a-9811-283c51ff232b";
          url = "https://youtube.com";
          position = 103;
          workspace = spaces."Personal".id;
          isEssential = false;
        };
        "Youtube Music" = {
          id = "09f0e772-b8a2-4e1e-b552-3169297a25cc";
          url = "https://music.youtube.com";
          position = 104;
          workspace = spaces."Personal".id;
          isEssential = false;
        };
        "Shupi" = {
          id = "d78b97c7-3719-4d8f-881d-1d2d62eaf082";
          url = "https://home.shupi.ushira.com";
          position = 105;
          workspace = spaces."Personal".id;
          isEssential = false;
        };
        "GitHub" = {
          id = "48e8a119-5a14-4826-9545-91c8e8dd3bf6";
          url = "https://github.com/ushiradineth";
          position = 106;
          workspace = spaces."Personal".id;
          isEssential = false;
        };
        "Monkeytype" = {
          id = "e23b1bd6-e511-4042-920d-172cde499932";
          url = "https://monkeytype.com";
          position = 107;
          workspace = spaces."Personal".id;
          isEssential = false;
        };
        "Miruro" = {
          id = "da2e9a28-a009-4721-85e5-e1272d223477";
          url = "https://miruro.to";
          position = 108;
          workspace = spaces."Personal".id;
          isEssential = false;
        };
      };

      search = {
        force = true;
        default = "ddg";
        engines = let
          nixSnowflakeIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        in {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "channel";
                    value = "25.11";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = nixSnowflakeIcon;
            definedAliases = ["np"];
          };
          "Nix Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "25.11";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = nixSnowflakeIcon;
            definedAliases = ["nop"];
          };
          "Home Manager Options" = {
            urls = [
              {
                template = "https://home-manager-options.extranix.com/";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                  {
                    name = "release";
                    value = "release-25.11";
                  }
                ];
              }
            ];
            icon = nixSnowflakeIcon;
            definedAliases = ["hmop"];
          };
          bing.metaData.hidden = "true";
        };
      };
    };
  };
}
