{...}: {
  services.vicinae = {
    enable = true;
    autoStart = true;
    useLayerShell = false;
    settings = {
      theme.name = "vicinae-dark";
      window = {
        csd = true;
        opacity = 0.75;
        rounding = 12;
      };
      terminal = "ghostty";
      browser = "zen-beta -P default";
    };
  };

  # Workaround for Hyprland layer shell issues (vicinaehq/vicinae#558)
  systemd.user.services.vicinae.Service.Environment = [
    "USE_LAYER_SHELL=0"
  ];
}
