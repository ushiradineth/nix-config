{mylib, ...}: {
  imports = mylib.scanPaths ./.;

  programs.nixvim.plugins = {
    web-devicons.enable = true;
    telescope.enable = true;
  };
}
