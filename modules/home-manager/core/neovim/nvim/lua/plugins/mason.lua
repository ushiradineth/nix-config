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
          -- Docker
          "docker_compose_language_service",
          "dockerls",

          -- YAML / TOML / JSON
          "yaml-language-server",
          "yamllint",
          "jsonlint",
          "jqls",
          "jsonls",
          "taplo", -- TOML LSP

          -- Bash
          "bashls",
          "beautysh", -- Bash formatter

          -- Markdown
          "markdownlint",
          "marksman",

          -- Misc
          "html",         -- HTML LSP
          "cssls",
          "diagnosticls", -- Diagnostics engine
          "sonarlint-language-server",
          "nginx_language_server",
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
