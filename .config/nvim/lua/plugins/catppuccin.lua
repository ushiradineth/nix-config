return {
  "catppuccin/nvim",
  lazy = false,
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup {
      default_integrations = false,
    }
    vim.cmd.colorscheme "catppuccin-mocha"
  end,
}
