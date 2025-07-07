{...}: {
  # Markdown preview
  programs.nixvim.plugins.markview = {
    enable = true;
    settings = {
      preview.enable = false;
    };
  };

  programs.nixvim.keymaps = [
    {
      key = "<leader>tm";
      action = ":Markview Toggle<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Toggle Markdown Preview";
      };
    }
  ];
}
