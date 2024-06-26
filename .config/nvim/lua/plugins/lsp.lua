return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup {
        ensure_installed = {
          "lua-language-server",
          "stylua",
          "html-lsp",
          "css-lsp",
          "luaformatter",
          "easy-coding-standard",
          "sqlls",
          "vue-language-server",
          "yamllint",
          "xmlformatter",
          "yaml-language-server",
          "sqls",
          "typescript-language-server",
          "tfsec",
          "tflint",
          "tailwindcss-language-server",
          "terraform-ls",
          "sqlfluff",
          "rustywind",
          "rust-analyzer",
          "python-lsp-server",
          "sqlfmt",
          "sql-formatter",
          "prisma-language-server",
          "prettierd",
          "pretty-php",
          "php-cs-fixer",
          "nginx-language-server",
          "lua-language-server",
          "json-lsp",
          "hclfmt",
          "helm-ls",
          "sonarlint-language-server",
          "grammarly-languageserver",
          "gopls",
          "golines",
          "golangci-lint-langserver",
          "goimports-reviser",
          "golangci-lint",
          "goimports",
          "gofumpt",
          "eslint_d",
          "elixir-ls",
          "dockerfile-language-server",
          "docker-compose-language-service",
          "checkmake",
          "beautysh",
          "bash-language-server",
          "bash-debug-adapter",
          "astro-language-server",
          "azure-pipelines-language-server",
          "ansible-lint",
          "autopep8",
          "ansible-language-server",
        },
      }
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup {
        ensure_installed = {
          "lua_ls",
          "tsserver",
        },
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require "lspconfig"
      lspconfig.lua_ls.setup {}
      lspconfig.tsserver.setup {}

      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, { desc = "Go to Definition" })
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
    end,
  },
}
