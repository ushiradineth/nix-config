local icon = function(icon, color)
	return {
		color = color or "blue",
		icon = icon,
		cat = "filetype",
		hl = "WhichKeyIcon",
	}
end

return { -- SHORTCUT DISPLAY
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
      { "<leader>w", group = "Save", icon = mini.get('file', 'TODO')}
		})
	end,
}
