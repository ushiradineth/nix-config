{pkgs, ...}: {
  # Search and replace
  programs.nixvim.plugins.spectre.enable = true;

  # Whitespace highlighting
  programs.nixvim.plugins.whitespace.enable = true;

  # Autopairing
  programs.nixvim.plugins.nvim-autopairs.enable = true;

  # HTML autopairing
  programs.nixvim.plugins.ts-autotag = {
    enable = true;
    settings = {
      opts = {
        enable_close = true; # Auto close tags
        enable_close_on_slash = true; # Auto close on trailing </
        enable_rename = true; # Auto rename pairs of tags
      };
    };
  };

  # Diagnostics
  programs.nixvim.plugins.trouble.enable = true;

  # AI code completion
  programs.nixvim.plugins.supermaven = {
    enable = true;
    settings = {
      log_level = "off";
    };
  };

  # Time tracking
  programs.nixvim.plugins.wakatime.enable = true;

  # Markdown preview
  programs.nixvim.plugins.markview = {
    enable = true;
    settings = {
      preview.enable = false;
    };
  };

  # TailwindCSS tools
  programs.nixvim.plugins.tailwind-tools.enable = true;

  # Plugins that are not in nixpkgs
  programs.nixvim.extraPlugins = [
    # Quick open `%s//gcI`
    (pkgs.vimUtils.buildVimPlugin {
      name = "search-replace.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "roobert";
        repo = "search-replace.nvim";
        rev = "main";
        hash = "sha256-hEdEBDeHbJc3efgo7djktX4RemAiX8ZvQlJIEoAgkPM=";
      };
    })

    # Move code blocks
    (pkgs.vimUtils.buildVimPlugin {
      name = "move.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "fedepujol";
        repo = "move.nvim";
        rev = "v2.0.0";
        hash = "sha256-aJi7r9yPdQyH6i8EtQzKdRhEQ3SLz32oqcN0tf2qRZA=";
      };
    })

    # # Terraform docs
    # (pkgs.vimUtils.buildVimPlugin {
    #   name = "treesitter-terraform-doc";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "Afourcat";
    #     repo = "treesitter-terraform-doc.nvim";
    #     rev = "main";
    #     hash = "sha256-dqfpA/7C906mK4ADwEda4wQu+vdGIRteIRvcmB50TRI=";
    #   };
    # })
  ];

  programs.nixvim.extraConfigLua = ''
    require("search-replace").setup({
      default_replace_single_buffer_options = "gcI",
    });
    require('move').setup({});
  '';
  # require('treesitter-terraform-doc').setup({});
}
