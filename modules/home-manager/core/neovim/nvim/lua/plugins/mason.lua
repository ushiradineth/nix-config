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
          "astro",
          "ts_ls",
          "vue_ls",
          "prismals",
          "tailwindcss", -- Tailwind LSP
          "jqls",
          "jsonls",
          "taplo",        -- TOML LSP
          "terraformls",  -- Terraform LSP
          "ansiblels",
          "pylsp",        -- Python LSP
          "dockerls",
          "gopls",        -- Go LSP
          "intelephense", -- PHP linter
          "lua_ls",
          "bashls",
          "marksman",      -- Markdown LSP
          "html",          -- HTML LSP
          "cssls",
          "diagnosticls",  -- Diagnostics engine
          "helm_ls",
          "rust_analyzer", -- Rust LSP
          "nginx_language_server",
          "typos_lsp",
        },
        automatic_enable = true,
        automatic_installation = false,
      })
      local lspconfig = require("lspconfig")
      lspconfig.nixd.setup({}) -- Nix LSP, installed with the nvim module
    end,
  },
  { "neovim/nvim-lspconfig", event = { "BufReadPre", "BufNewFile", "BufEnter" } },
}
