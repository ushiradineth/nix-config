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
      "  font-weight: bold;"
      "  border-radius: 0px;"
      "  border: none;"
      "  min-height: 0px;"
      "  color: @text;"
      "}"
      "window#waybar {"
      "  background-color: shade(@base, 0.9);"
      "  border: 2px solid alpha(@crust, 0.3);"
      "}"
      "#workspaces button { padding: 0px 5px; background: transparent; }"
      "tooltip { border-radius: 12px; }"
      "#window, #custom-clock-notification { padding: 0px 10px; }"
      "#custom-startmenu {"
      "  padding: 0px 10px;"
      "  font-size: 20px;"
      "}"
      "#tray { padding: 0px 10px; }"
    ];
  };
}
