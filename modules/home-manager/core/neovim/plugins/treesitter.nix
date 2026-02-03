{pkgs, ...}: {
  programs.nixvim.plugins.treesitter = {
    enable = true;
    grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      bash
      comment
      dockerfile
      go
      json
      lua
      markdown
      markdown_inline
      nix
      rust
      terraform
      tsx
      typescript
      yaml
      helm
      heex
      elixir
      erlang
      gleam
    ];

    settings = {
      auto_install = false;
      sync_install = false;
      highlight = {
        enable = true;
        additional_vim_regex_highlighting = true;
      };
      indent = {enable = true;};
      incremental_selection = {enable = true;};
    };
  };
}
