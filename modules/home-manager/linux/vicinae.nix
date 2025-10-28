{...}: {
  services.vicinae = {
    enable = true;
    autoStart = true;
    settings = {
      theme.name = "catppuccin-frappe";
      window = {
        csd = true;
        opacity = 0.75;
        rounding = 10;
      };
      terminal = "ghostty";
      browser = "zen";
    };
  };
}
