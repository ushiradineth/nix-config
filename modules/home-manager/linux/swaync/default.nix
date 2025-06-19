{pkgs, ...}: let
  theme = builtins.readFile ./catppuccin-frappe.css;
in {
  services.swaync = {
    enable = true;
    style = theme;
  };
}
