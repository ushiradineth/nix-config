{...}: {
  services.vicinae = {
    enable = true;
    autoStart = true;
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
}
