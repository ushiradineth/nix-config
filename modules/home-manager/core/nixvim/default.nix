{
  inputs,
  mylib,
  ...
}: {
  imports = mylib.scanPaths ./.;

  programs.nixvim = {
    enable = true;

    plugins = {
      web-devicons.enable = true;
      telescope.enable = true;
      treesitter.enable = true;
    };
  };
}
