return {
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvimtools/none-ls-extras.nvim",
    },
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.stylua,
          require "none-ls.diagnostics.eslint_d".with({
            diagnostics_format = "[eslint] #{m}\n(#{c})",
          }),
          require "none-ls.formatting.eslint_d".with({
            diagnostics_format = "[eslint] #{m}\n(#{c})",
          }),
          null_ls.builtins.formatting.prettierd,
        },
      })

      vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, { noremap = true, silent = true, desc = "Format" })
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    },
    config = function()
      require("mason-null-ls").setup({
        ensure_installed = {
          "stylua",
          "easy-coding-standard",
          "yamllint",
          "xmlformatter",
          "tfsec",
          "sqlfluff",
          "rustywind",
          "sqlfmt",
          "sql-formatter",
          "prettierd",
          "pretty-php",
          "php-cs-fixer",
          "hclfmt",
          "golines",
          "golangci-lint-langserver",
          "goimports-reviser",
          "golangci-lint",
          "goimports",
          "gofumpt",
          "checkmake",
          "beautysh",
          "bash-debug-adapter",
          "ansible-lint",
          "autopep8",
          "eslint_d",
          "jsonlint",
          "markdownlint",
          "sonarlint-language-server",
          "yaml-language-server",
        },
      })
    end,
  },
}
