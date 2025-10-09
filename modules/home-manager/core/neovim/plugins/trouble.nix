{...}: {
  # Diagnostics
  programs.nixvim.plugins.trouble.enable = true;

  programs.nixvim.keymaps = [
    {
      key = "<leader>dd";
      action = ":Trouble diagnostics toggle<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Diagnostics";
      };
    }
    {
      key = "<leader>dD";
      action = ":Trouble diagnostics toggle filter.buf=0<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Buffer Diagnostics";
      };
    }
  ];
}
