local catppuccin = {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			transparent_background = vim.g.transparent_enabled,
		})

		vim.cmd.colorscheme("catppuccin-mocha")
	end,
}

local rosepine = {
	"rose-pine/neovim",
	name = "rose-pine",
	lazy = false,
	priority = 1000,
	config = function()
		require("rose-pine").setup({
			styles = {
				transparent = vim.g.transparent_enabled,
			},
		})

		vim.cmd.colorscheme("rose-pine-moon")
	end,
}

return rosepine
