_: {
  programs.nixvim.plugins.zen-mode.enable = true;

  programs.nixvim.plugins.zen-mode.settings = {
    on_open = {
      __raw = ''
        function()
          vim.g._zen_laststatus = vim.o.laststatus
          vim.o.laststatus = 0
        end
      '';
    };
    on_close = {
      __raw = ''
        function()
          if vim.g._zen_laststatus ~= nil then
            vim.o.laststatus = vim.g._zen_laststatus
            vim.g._zen_laststatus = nil
          else
            vim.o.laststatus = 3
          end
        end
      '';
    };
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
}
