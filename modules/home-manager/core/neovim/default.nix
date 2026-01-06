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
    clang-tools # C/C++ linter
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

    # Suppress lspconfig deprecation warning
    extraConfigLuaPre = ''
      -- Silence lspconfig deprecation warnings
      vim.deprecate = function() end
    '';
  };
}
