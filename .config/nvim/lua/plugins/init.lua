return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    config = function()
      require "configs.conform"
    end,
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server", "stylua",
        "html-lsp", "css-lsp", "prettier",
        "luaformatter", "easy-coding-standard", "sqlls",
        "vue-language-server", "yamllint", "xmlformatter",
        "yaml-language-server", "sqls", "typescript-language-server",
        "tfsec", "tflint", "tailwindcss-language-server",
        "terraform-ls", "sqlfluff", "rustywind",
        "rust-analyzer", "python-lsp-server", "sqlfmt", "sql-formatter",
        "prisma-language-server", "prettierd", "pretty-php",
        "php-cs-fixer", "nginx-language-server", "lua-language-server",
        "json-lsp", "hclfmt", "helm-ls", "sonarlint-language-server",
        "grammarly-languageserver", "gopls", "golines",
        "golangci-lint-langserver", "goimports-reviser", "golangci-lint",
        "goimports", "gofumpt", "eslint_d",
        "elixir-ls", "dockerfile-language-server", "docker-compose-language-service",
        "checkmake", "beautysh", "bash-language-server",
        "bash-debug-adapter", "astro-language-server", "azure-pipelines-language-server",
        "ansible-lint", "autopep8", "ansible-language-server"
      },
    },
  },
  --
  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
