{
  pkgs,
  mylib,
  ...
}: {
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    lua5_1 # Some packages require lua5_1 to be installed
    luarocks
    stylua
    nixd # Nix LSP, enabled with mason-lspconfig
    unzip # Needed for terraform-ls

    python311 # For plugins that require python
    nodejs # For plugins that require node
    go # For plugins that require go

    # Formatters and Linters
    typos
    biome
    prettierd
    markdownlint-cli
    beautysh
    yamlfix
    alejandra # Nix formatter
    codespell # Spell checker for code
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    withNodeJs = false;
    withPerl = false;
    withPython3 = false;
    withRuby = false;

    luaLoader.enable = true;

    performance.byteCompileLua = {
      enable = true;
      configs = true;
      initLua = true;
      nvimRuntime = true;
      plugins = true;
    };
  };
}
