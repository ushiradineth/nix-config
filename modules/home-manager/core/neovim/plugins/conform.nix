{...}: {
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
        astro = ["biome"];
        json = ["biome"];
        jsonc = ["biome"];
        html = ["biome"];
        css = ["biome"];
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
        "*" = ["codespell"];
        "_" = [
          "squeeze_blanks"
          "trim_whitespace"
          "trim_newlines"
        ];
      };

      formatters = {
        biome = {
          require_cwd = true;
        };
        yamlfix = {
          env = {
            YAMLFIX_WHITELINES = "1";
          };
        };
      };

      format_on_save = ''
        function(bufnr)
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          if bufname:match("/node_modules/") then
            return
          end
          return { timeout_ms = 1000, lsp_fallback = true }
        end
      '';

      format_after_save = {
        lsp_fallback = true;
      };
    };
  };

  programs.nixvim.keymaps = [
    {
      key = "<leader>cf";
      action = ":lua require('conform').format({ timeout_ms = 1000, lsp_fallback = true })<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Format";
      };
    }
  ];
}
