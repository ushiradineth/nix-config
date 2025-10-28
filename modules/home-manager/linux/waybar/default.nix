{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    bluetuith
  ];

  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";

        modules-left = ["custom/startmenu"];
        modules-center = ["hyprland/workspaces"];
        modules-right = ["tray" "bluetooth" "network" "custom/clock-notification"];

        "hyprland/workspaces" = {
          format = "{name}";
          format-icons = {
            default = " ";
            active = " ";
            urgent = " ";
          };
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };

        "custom/startmenu" = {
          tooltip = false;
          format = "";
          on-click = "sleep 0.1 && vicinae toggle";
        };

        tray = {
          icon-size = 18;
          spacing = 8;
        };

        bluetooth = {
          format = "";
          format-connected = "󰂯";
          format-connected-battery = "󰂯";
          tooltip-format-connected = "{num_connections} devices connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
          tooltip-format-enumerate-connected-battery = "{device_alias} - {device_battery_percentage}%";
          on-click = "ghostty -e bluetuith";
        };

        network = {
          format-wifi = "󰖩";
          format-ethernet = "󰖩";
          format-linked = "󰖩";
          format-disconnected = "󰖪";
          tooltip-format-wifi = "Wi-Fi connected\n\n{ipaddr} @ {essid} - Signal {signalStrength}%";
          tooltip-format-ethernet = "Ethernet connected\n\n{ipaddr} @ {ifname}";
          tooltip-format-disconnected = "Not Connected";
          on-click = "ghostty -e nmtui";
        };

        "custom/clock-notification" = {
          interval = 1;
          format = "{}";
          return-type = "json";
          exec-if = "which swaync-client";
          exec = ''
            bash -c 't=$(date "+%a %d %b %H:%M"); echo "{\"text\": \"$t\", \"alt\": \"$t\"}"'
          '';
          on-click = "swaync-client -t";
        };
      }
    ];

    style = lib.concatStringsSep "\n" [
      "* {"
      "  font-family: Geist;"
      "  font-size: 14px;"
      "  font-weight: 600;"
      "  border-radius: 12px;"
      "  border: none;"
      "  min-height: 0px;"
      "  margin: 0.5px 8px;"
      "  padding: 0px;"
      "  color: @text;"
      "}"
      "window#waybar {"
      "  background: rgba(48, 52, 70, 0.5);"
      "  border-radius: 0px;"
      "  border-bottom: 1px solid rgba(255, 255, 255, 0.05);"
      "  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);"
      "}"
      "#workspaces button {"
      "  box-shadow: none;"
      "  text-shadow: none;"
      "  margin: 0px;"
      "  padding: 0px;"
      "  color: #f1f1f1;"
      "}"
      "tooltip {"
      "  background: rgba(0, 0, 0, 0.5);"
      "  border: 1px solid rgba(255, 255, 255, 0.1);"
      "}"
      "tooltip label {"
      "  padding: 0px;"
      "  margin: 8px 0px;"
      "}"
      "#custom-clock-notification {"
      "  margin: 0px;"
      "  margin-left: 8px;"
      "}"
      "#custom-startmenu {"
      "  margin: 0px;"
      "  margin-right: 8px;"
      "}"
    ];
  };
}
