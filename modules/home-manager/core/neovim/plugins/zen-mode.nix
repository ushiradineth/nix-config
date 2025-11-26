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

  programs.nixvim.keymaps = [
    {
      key = "<leader>z";
      action = ":ZenMode<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Zen Mode";
      };
    }
  ];

  # TODO: Add onOpen/onClose events for lualine
}
