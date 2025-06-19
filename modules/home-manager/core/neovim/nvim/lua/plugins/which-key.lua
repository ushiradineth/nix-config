return {
  -- SHORTCUT DISPLAY
  "folke/which-key.nvim",
  event = "VeryLazy",
  dependencies = {
    "echasnovski/mini.icons",
    "nvim-tree/nvim-web-devicons",
  },
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  config = function()
    local wk = require("which-key")
    local mini = require("mini.icons")
    wk.add({
      { "<leader>c", group = "Code" },
      { "<leader>d", group = "Diagnostics" },
      { "<leader>g", group = "Git" },
      { "<leader>gr", group = "Repo" },
      { "<leader>l", group = "Line", icon = "⋯" },
      { "<leader>q", group = "Quit" },
      { "<leader>s", group = "Search" },
      { "<leader>sw", group = "Highlighted Word" },
      { "<leader>w", group = "Save", icon = mini.get("file", "TODO") },
      { "<leader>r", group = "Replace" },
      { "<leader>t", group = "Toggle" },
    })
  end,
}
