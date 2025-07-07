{pkgs, ...}: let
  ignore_patterns = [
    ".git/*"
    "node_modules/*"
    ".next/*"
    ".nuxt/*"
    "dist/*"
    "build/*"
    "target/*"
    "*-lock.yaml"
    "*-lock.json"
    "*.tfvars"
    ".direnv/*"
  ];
in {
  programs.nixvim.plugins.telescope = {
    enable = true;
    extensions = {
      fzf-native = {
        enable = true;
        settings = {
          case_mode = "smart_case";
          fuzzy = true;
          override_file_sorter = true;
          override_generic_sorter = true;
        };
      };
      ui-select.enable = true;
      live-grep-args = {
        enable = true;
        settings = {
          auto_quoting = true;
          theme = "dropdown";
          mappings = {
            i = {
              "<C-t>".__raw = "require('telescope-live-grep-args.actions').quote_prompt({ postfix = ' -t rs' })";
              "<C-i>".__raw = "require('telescope-live-grep-args.actions').quote_prompt({ postfix = ' --iglob **/*.rs' })";
            };
          };
        };
      };
    };

    settings = {
      defaults = {
        vimgrep_arguments = [
          "${pkgs.ripgrep}/bin/rg"
          "-L"
          "--color=never"
          "--no-heading"
          "--with-filename"
          "--line-number"
          "--column"
          "--smart-case"
          "--fixed-strings"
          "--hidden"
          "--trim"
          "--ignore-file"
          ".gitignore"
        ];
        file_ignore_patterns = ignore_patterns;
        set_env = {
          COLORTERM = "truecolor";
        };
        layout_strategy = "vertical";
      };

      pickers = {
        find_files = {
          hidden = true;
          file_ignore_patterns = ignore_patterns;
        };
      };
    };
  };

  programs.nixvim.keymaps = [
    {
      key = "<D-p>";
      mode = ["n"];
      action = ":Telescope find_files<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Search files";
      };
    }
    {
      key = "<C-p>";
      mode = ["n"];
      action = ":Telescope find_files<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Search files";
      };
    }
    {
      key = "<M-p>";
      mode = ["n"];
      action = ":Telescope find_files<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Search files";
      };
    }

    {
      # Initiate search in all files in the current working directory
      key = "<leader>sa";
      mode = ["n"];
      action = ":Telescope live_grep_args<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Working directory";
      };
    }
    {
      # Initiate search for the word under the cursor in the working directory
      key = "<leader>swa";
      mode = ["n"];
      action.__raw = ''
        require('telescope-live-grep-args.shortcuts').grep_word_under_cursor
      '';
      options = {
        noremap = true;
        silent = true;
        desc = "Working Directory";
      };
    }
    {
      # Initiate search in the current file
      key = "<leader>sc";
      mode = ["n"];
      action = ":Telescope current_buffer_fuzzy_find<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Current Buffer";
      };
    }
    {
      # Initiate search for the word under the cursor in the current buffer
      key = "<leader>swc";
      mode = ["n"];
      action.__raw = ''
        require('telescope-live-grep-args.shortcuts').grep_word_under_cursor_current_buffer
      '';
      options = {
        noremap = true;
        silent = true;
        desc = "Current Buffer";
      };
    }
    {
      # Initiate search in all symbols exposed by the LSP
      key = "<leader>st";
      mode = ["n"];
      action = ":Telescope lsp_workspace_symbols<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "All symbols";
      };
    }
    {
      # List the current file's git history
      key = "<leader>gc";
      mode = ["n"];
      action = ":Telescope git_bcommits<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Telescope commits";
      };
    }
    {
      # List the current git repository's history
      key = "<leader>grc";
      mode = ["n"];
      action = ":Telescope git_commits<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Telescope commits";
      };
    }
    {
      # List the changed files in the current git repository
      key = "<leader>gs";
      mode = ["n"];
      action = ":Telescope git_status<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Telescope changed files";
      };
    }
    {
      # Resume the last search
      key = "<leader>ss";
      mode = ["n"];
      action = ":Telescope resume<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Resume";
      };
    }
  ];
}
