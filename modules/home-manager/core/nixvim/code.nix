{...}: {
  # TODO: add search and replace

  programs.nixvim.plugins.spectre.enable = true;

  programs.nixvim.plugins.nvim-autopairs.enable = true;

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

  # TODO: add move

  programs.nixvim.plugins.trouble.enable = true;

  programs.nixvim.plugins.supermaven = {
    enable = true;
    settings = {
      log_level = "off";
    };
  };

  programs.nixvim.plugins.wakatime.enable = true;

  # programs.nixvim.plugins.markview = {
  #   enable = true;
  #   settings = {
  #     preview.enable = false;
  #   };
  # };
  #
  # TODO: add treesitter-terraform-doc

  programs.nixvim.plugins.tailwind-tools.enable = true;
}
