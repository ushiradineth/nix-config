return {
  { -- PACKAGE MANAGER
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({})
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- -- Ansible
          -- "ansiblels",
          -- "ansible-lint",
          --
          -- -- Python
          -- "autopep8", -- Python formatter
          -- "pylsp",    -- Python LSP
          --
          -- -- Docker
          -- "docker_compose_language_service",
          -- "dockerls",
          --
          -- -- Javascript / Typescript
          -- "astro",
          -- "eslint_d",
          -- "prettier",
          -- "biome",
          -- "ts_ls",
          -- "vue_ls",
          -- "prismals",
          -- "rustywind",   -- Tailwind formatter
          -- "tailwindcss", -- Tailwind LSP
          --
          -- -- Go
          -- "gopls",     -- Go Language Server
          -- "gofumpt",   -- Go formatter
          -- "goimports", -- Go formatter for imports
          -- "golines",   -- Go formatter for long lines
          --
          -- -- PHP
          -- "intelephense", -- PHP linter
          -- "php-cs-fixer",
          --
          -- -- SQL
          -- "sqlfluff", -- SQL linter
          -- "sqlfmt",   -- SQL formatter
          -- "sqlls",    -- SQL LSP
          --
          -- -- Lua
          -- "lua_ls",
          -- "stylua", -- Lua formatter
          --
          -- -- YAML / TOML / JSON
          -- "yaml-language-server",
          -- "yamllint",
          -- "jsonlint",
          -- "jqls",
          -- "jsonls",
          -- "taplo", -- TOML LSP
          --
          -- -- Terraform
          -- "terraformls", -- Terraform LSP
          -- "tflint",      -- Terraform linter
          -- "tfsec",       -- Terraform security linter
          -- "hclfmt",
          --
          -- -- Bash
          -- "bashls",
          -- "beautysh", -- Bash formatter
          --
          -- -- Markdown
          -- "markdownlint",
          -- "marksman",
          --
          -- -- Misc
          -- "html",         -- HTML LSP
          -- "cssls",
          -- "checkmake",    -- Makefile linter
          -- "diagnosticls", -- Diagnostics engine
          -- "sonarlint-language-server",
          -- "grammarly",
          -- "helm_ls",
          -- "nginx_language_server",
          -- "rust_analyzer",
          -- "trivy", -- Security Linter
          -- "typos_lsp",
        },
        automatic_enable = true, -- Manually enable servers with custom config
        automatic_installation = true,
      })
      local lspconfig = require("lspconfig")
      lspconfig.nixd.setup({}) -- Nix LSP
    end,
  },
  { "neovim/nvim-lspconfig", event = { "BufReadPre", "BufNewFile", "BufEnter" } },
}
