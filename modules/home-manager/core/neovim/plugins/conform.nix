{
  lib,
  pkgs,
  ...
}: {
  programs.nixvim.plugins.conform-nvim = {
    enable = true;

    settings = {
      quiet = true;
      notify_on_error = true;
      notify_no_formatters = true;
      log_level = "warn";

      default_format_opts = {
        lsp_format = "fallback";
      };

      formatters_by_ft = {
        javascript = {
          __unkeyed-1 = "biome";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        typescript = {
          __unkeyed-1 = "biome";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        javascriptreact = {
          __unkeyed-1 = "biome";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        typescriptreact = {
          __unkeyed-1 = "biome";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        astro = {
          __unkeyed-1 = "biome";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        json = {
          __unkeyed-1 = "biome";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        jsonc = {
          __unkeyed-1 = "biome";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        html = {
          __unkeyed-1 = "biome";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        css = {
          __unkeyed-1 = "biome";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        markdown = {
          __unkeyed-1 = "markdownlint";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        md = {
          __unkeyed-1 = "markdownlint";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        sh = {
          __unkeyed-1 = "beautysh";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        bash = {
          __unkeyed-1 = "beautysh";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        zsh = {
          __unkeyed-1 = "beautysh";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        yaml = ["yamlfix"];
        go = ["goimports-reviser" "gofumpt"];
        terraform = ["terraform_fmt"];
        lua = ["stylua"];
        rust = ["rustfmt"];
        php = ["pretty-php"];
        nix = ["alejandra"];
        c = ["clang-format"];
        cpp = ["clang-format"];
        "_" = [
          "squeeze_blanks"
          "trim_whitespace"
          "trim_newlines"
        ];
      };

      formatters = {
        biome = {
          # The built-in cwd searches for biome.json / biome.jsonc (including dotfiles).
          require_cwd = true;
        };
        prettier = {
          command.__raw = ''
            require("conform.util").find_executable({ "node_modules/.bin/prettier" }, "${lib.getExe pkgs.prettier}")
          '';
        };
        yamlfix = {
          env = {
            YAMLFIX_WHITELINES = "1";
          };
        };
      };

      format_on_save.__raw = ''
        function(bufnr)
          if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then
            return
          end
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          if bufname:match("/node_modules/") then
            return
          end
          return { timeout_ms = 1000, lsp_format = "fallback" }
        end
      '';
    };
  };

  programs.nixvim.keymaps = [
    {
      key = "<leader>cf";
      action = ":lua require('conform').format({ timeout_ms = 1000, lsp_format = 'fallback' })<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Format";
      };
    }
    {
      key = "<leader>tf";
      mode = "n";
      action.__raw = ''
        function()
          vim.g.autoformat = vim.g.autoformat == false
          vim.notify("Autoformat (global): " .. (vim.g.autoformat and "enabled" or "disabled"))
        end
      '';
      options = {
        silent = true;
        desc = "Toggle autoformat (global)";
      };
    }
    {
      key = "<leader>tF";
      mode = "n";
      action.__raw = ''
        function()
          vim.b.autoformat = vim.b.autoformat == false
          vim.notify("Autoformat (buffer): " .. (vim.b.autoformat and "enabled" or "disabled"))
        end
      '';
      options = {
        silent = true;
        desc = "Toggle autoformat (buffer)";
      };
    }
  ];
}
