{...}: {
  programs.nixvim.plugins.transparent.enable = true;
  programs.nixvim.colorschemes.catppuccin = {
    enable = true;
    settings.flavour = "frappe";
  };

  programs.nixvim.keymaps = [
    {
      key = "<leader>tt";
      action = ":TransparentToggle<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Toggle Transparency";
      };
    }
  ];
}
