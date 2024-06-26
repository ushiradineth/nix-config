return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  config = function()
    local wk = require "which-key"
    opts = {
      wk.register({
        c = { name = "Code" },
        g = { name = "Git" },
        l = { name = "Line" },
      }, { prefix = "<leader>" }),
    }
  end,
}
