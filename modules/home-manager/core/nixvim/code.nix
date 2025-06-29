{...}: {
  programs.nixvim.plugins.supermaven = {
    enable = true;
    settings = {
      log_level = "off";
    };
  };
}
