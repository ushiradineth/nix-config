return {
  {
    -- WHITESPACE HIGHLIGHTER
    "zakharykaplan/nvim-retrail",
    config = function()
      require("retrail").setup({
        filetype = {
          exclude = {
            "markdown",
            "neo-tree",
            -- following are defaults that need to be added or they'll be overridden
            "",
            "alpha",
            "checkhealth",
            "diff",
            "help",
            "lspinfo",
            "man",
            "mason",
            "TelescopePrompt",
            "Trouble",
            "WhichKey",
          },
        },
      })
    end,
  },
  { -- SYNTAX HIGHLIGHTING
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "astro",
          "bash",
          "comment",
          "dockerfile",
          "go",
          "gotmpl",
          "hcl",
          "helm",
          "javascript",
          "json",
          "kconfig",
          "lua",
          "markdown",
          "markdown_inline",
          "nix",
          "python",
          "sql",
          "terraform",
          "tsx",
          "typescript",
          "yaml",
        },
        highlight = { enable = true, additional_vim_regex_highlighting = true },
        indent = { enable = true },
        incremental_selection = { enable = true },
        auto_install = true, -- Auto install missing parsers when entering a buffer
        sync_install = true,
      })
    end,
  },
  {
    -- AUTOPAIRING
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
  {
    -- HTML AUTOPAIRING
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          enable_close = true,     -- Auto close tags
          enable_rename = true,    -- Auto rename pairs of tags
          enable_close_on_slash = true, -- Auto close on trailing </
        },
      })
    end,
  },
  {
    -- MOVE CODE BLOCKS
    "fedepujol/move.nvim",
    config = function()
      require("move").setup({})

      vim.keymap.set("n", "<A-j>", ":MoveLine(1)<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<A-k>", ":MoveLine(-1)<CR>", { noremap = true, silent = true })
      vim.keymap.set("v", "<A-j>", ":MoveBlock(1)<CR>", { noremap = true, silent = true })
      vim.keymap.set("v", "<A-k>", ":MoveBlock(-1)<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<A-Down>", ":MoveLine(1)<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<A-Up>", ":MoveLine(-1)<CR>", { noremap = true, silent = true })
      vim.keymap.set("v", "<A-Down>", ":MoveBlock(1)<CR>", { noremap = true, silent = true })
      vim.keymap.set("v", "<A-Up>", ":MoveBlock(-1)<CR>", { noremap = true, silent = true })
    end,
  },
  {
    -- WORD HIGHLIGHTER
    "RRethy/vim-illuminate",
  },
  {
    -- DIAGNOSTICS
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>dD",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics",
      },
      {
        "<leader>dd",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics",
      },
    },
  },
}
