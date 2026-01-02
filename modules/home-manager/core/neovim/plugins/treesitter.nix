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
    ];

    settings = {
      auto_install = true;
      sync_install = true;
      highlight = {
        enable = true;
        additional_vim_regex_highlighting = true;
      };
      indent = {enable = true;};
      incremental_selection = {enable = true;};
    };
  };
}
