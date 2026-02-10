_: {
  # Whitespace highlighting
  programs.nixvim.plugins.whitespace.enable = true;

  # Autopairing
  programs.nixvim.plugins.nvim-autopairs.enable = true;

  # HTML autopairing
  programs.nixvim.plugins.ts-autotag = {
    enable = true;
    settings = {
      opts = {
        enable_close = true; # Auto close tags
        enable_close_on_slash = true; # Auto close on trailing </
        enable_rename = true; # Auto rename pairs of tags
      };
    };
  };

  # AI code completion
  programs.nixvim.plugins.supermaven = {
    enable = true;
    settings = {
      log_level = "off";
    };
  };

  # Time tracking
  programs.nixvim.plugins.wakatime.enable = true;
}
