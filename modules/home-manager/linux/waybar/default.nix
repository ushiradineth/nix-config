{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.home;
  waybarDir = "${cfg.homeDirectory}/.config/waybar";
in {
  home.file."${waybarDir}/theme.css" = {
    text = builtins.readFile ./catppuccin-frappe.css;
  };

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
          on-click = "sleep 0.1 && rofi -show drun";
        };

        tray = {
          icon-size = 18;
          spacing = 8;
        };

        bluetooth = {
          format = "";
          format-connected = "󰂯";
          format-connected-battery = "󰂯";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "ghostty -e bluetuith";
        };

        network = {
          format-wifi = "󰖩";
          format-ethernet = "󰖩";
          format-linked = "󰖩";
          format-disconnected = "󰖪";
          tooltip-format = "{ifname} via {gwaddr}";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          tooltip-format-ethernet = "{ifname}";
          tooltip-format-disconnected = "Disconnected";
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
      "@import \"theme.css\";"
      "* {"
      "  font-family: JetBrainsMono Nerd Font Mono;"
      "  font-size: 14px;"
      "  font-weight: 600;"
      "  border-radius: 0px;"
      "  border: none;"
      "  min-height: 0px;"
      "  color: @text;"
      "}"
      "window#waybar {"
      "  background: rgba(48, 52, 70, 0.5);"
      "  border-radius: 0px;"
      "  border-bottom: 1px solid rgba(255, 255, 255, 0.05);"
      "  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);"
      "}"
      "#workspaces {"
      "  background: transparent;"
      "  margin: 0 8px;"
      "}"
      "#workspaces button {"
      "  padding: 0px 6px;"
      "  margin: 0 2px;"
      "  background: transparent;"
      "  color: rgba(255, 255, 255, 0.5);"
      "  border-radius: 0px;"
      "  font-weight: 400;"
      "  transition: all 0.2s ease;"
      "}"
      "#workspaces button:hover {"
      "  color: rgba(255, 255, 255, 0.8);"
      "}"
      "#workspaces button.active {"
      "  background: transparent;"
      "  color: @text-active;"
      "  font-weight: 800;"
      "  box-shadow: none;"
      "  border: none;"
      "}"
      "#workspaces button.urgent {"
      "  color: @red;"
      "}"
      "tooltip {"
      "  background: rgba(48, 52, 70, 0.95);"
      "  border-radius: 12px;"
      "  border: 1px solid rgba(255, 255, 255, 0.1);"
      "}"
      "#custom-clock-notification {"
      "  padding: 0px 10px;"
      "  background: transparent;"
      "}"
      "#custom-startmenu {"
      "  padding: 0px 10px;"
      "  font-size: 18px;"
      "  background: transparent;"
      "  transition: all 0.2s ease;"
      "}"
      "#custom-startmenu:hover {"
      "  opacity: 0.8;"
      "}"
      "#tray {"
      "  padding: 0px 10px;"
      "  background: transparent;"
      "}"
      "#bluetooth {"
      "  padding: 0px 10px;"
      "  background: transparent;"
      "  transition: all 0.2s ease;"
      "}"
      "#bluetooth:hover {"
      "  opacity: 0.8;"
      "}"
      "#network {"
      "  padding: 0px 10px;"
      "  background: transparent;"
      "  transition: all 0.2s ease;"
      "}"
      "#network:hover {"
      "  opacity: 0.8;"
      "}"
    ];
  };
}
