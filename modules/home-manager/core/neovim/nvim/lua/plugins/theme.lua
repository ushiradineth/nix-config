local catppuccin = {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			transparent_background = vim.g.transparent_enabled,
		})
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
	end,
}

local tokyonight = {
	"folke/tokyonight.nvim",
	name = "tokyonight",
	lazy = false,
	priority = 1000,
	config = function()
		require("tokyonight").setup({
			transparent = vim.g.transparent_enabled,
		})
	end,
}

local nord = {
	"gbprod/nord.nvim",
	name = "nord",
	lazy = false,
	priority = 1000,
	config = function()
		require("nord").setup({
			transparent = vim.g.transparent_enabled,
		})
	end,
}

local onedark = {
	"navarasu/onedark.nvim",
	name = "onedark",
	lazy = false,
	priority = 1000,
	config = function()
		require("onedark").setup({
			transparent = vim.g.transparent_enabled,
		})
	end,
}

return {
	{
		-- UI TRANSPARENCY
		"xiyaowong/transparent.nvim",
		config = function()
			local transparent = require("transparent")

			transparent.setup({
				extra_groups = {
					-- "NormalFloat", -- plugins which have float panel such as Lazy, Mason, LspInfo
				},
			})

			transparent.clear_prefix("lualine")
			transparent.clear_prefix("NeoTree")

			vim.keymap.set(
				"n",
				"<Leader>tt",
				":TransparentToggle<CR>",
				{ noremap = true, silent = true, desc = "Toggle Transparency" }
			)
		end,
	},
	{
		-- THEME PICKER
		"lmantw/themify.nvim",
		lazy = false,
		priority = 999,
		config = function()
			require("themify").setup({
				catppuccin,
				rosepine,
				tokyonight,
				nord,
				onedark,
				"default",
			})
			vim.keymap.set(
				"n",
				"<Leader>ts",
				":Themify<CR>",
				{ noremap = true, silent = true, desc = "Theme Switcher" }
			)
		end,
	},
}
