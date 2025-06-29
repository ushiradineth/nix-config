{
  inputs,
  mylib,
  ...
}: {
  imports = mylib.scanPaths ./.;

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    performance = {
      byteCompileLua.enable = true;
      combinePlugins.enable = true;
    };

    globals.mapleader = " ";

    opts = {
      expandtab = true;
      tabstop = 2;
      softtabstop = 2;
      shiftwidth = 2;
      laststatus = 3;
    };

    clipboard.register = "unnamedplus";

    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "frappe";
    };

    plugins = {
      web-devicons.enable = true;
      telescope.enable = true;
      treesitter.enable = true;
    };
  };
}
