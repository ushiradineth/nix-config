local catppuccin = {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup()

    vim.cmd.colorscheme "catppuccin-mocha"
  end,
}

local rosepine = {
  "rose-pine/neovim",
  name = "rose-pine",
  lazy = false,
  priority = 1000,
  config = function()
    require("rose-pine").setup {}

    vim.cmd.colorscheme "rose-pine-moon"
  end,
}

return catppuccin
