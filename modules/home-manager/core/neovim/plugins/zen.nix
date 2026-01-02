{...}: {
  programs.nixvim.plugins.zen-mode.enable = true;

  programs.nixvim.plugins.zen-mode.settings = {
    # plugins = {
    #   tmux = true;
    # };
    window = {
      backdrop = 1;
    };
  };

  programs.nixvim.plugins.twilight = {
    enable = true;

    settings = {
      dimming = {
        alpha = 0.25;
      };

      context = 10;
      treesitter = true;
    };
  };

  programs.nixvim.keymaps = [
    {
      key = "<leader>z";
      action = ":ZenMode<CR> Twilight<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Zen Mode";
      };
    }
  ];

  # TODO: Add onOpen/onClose events for lualine
}
