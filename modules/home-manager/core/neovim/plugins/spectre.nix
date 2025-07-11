{...}: {
  # Search and replace
  programs.nixvim.plugins.spectre.enable = true;

  programs.nixvim.keymaps = [
    {
      key = "<leader>rs";
      mode = ["n"];
      action = ":Spectre<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Open Spectre";
      };
    }
  ];
}
