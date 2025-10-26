{
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

  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";

        modules-left = ["custom/startmenu"];
        modules-center = ["hyprland/workspaces"];
        modules-right = ["custom/clock-notification"];

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
      "  color: @lavender;"
      "}"
      "#tray {"
      "  padding: 0px 10px;"
      "  background: transparent;"
      "}"
    ];
  };
}
