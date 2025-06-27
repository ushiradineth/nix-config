return {
	-- START SCREEN
	"goolord/alpha-nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},

	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")
		local theta = require("alpha.themes.theta")

		local header = {
			type = "text",
			val = {
				[[                                  __]],
				[[     ___     ___    ___   __  __ /\_\    ___ ___]],
				[[    / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\]],
				[[   /\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \]],
				[[   \ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
				[[    \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
			},
			opts = {
				position = "center",
				hl = "Type",
				-- wrap = "overflow";
			},
		}

		local section_mru = {
			type = "group",
			val = {
				{
					type = "text",
					val = "Recent files",
					opts = {
						hl = "SpecialComment",
						shrink_margin = false,
						position = "center",
					},
				},
				{ type = "padding", val = 1 },
				{
					type = "group",
					val = function()
						return { theta.mru(0, vim.fn.getcwd()) }
					end,
					opts = { shrink_margin = false },
				},
			},
		}

		local buttons = {
			type = "group",
			val = {
				{ type = "text", val = "Quick links", opts = { hl = "SpecialComment", position = "center" } },
				{ type = "padding", val = 1 },
				dashboard.button("e", "New file", "<cmd>ene<CR>"),
				dashboard.button("CMD + P", "Find file"),
				dashboard.button("LEADER + s + a", "Find in workspace"),
				dashboard.button("LEADER + r + s", "Search and replace"),
				dashboard.button("u", "Update plugins", "<cmd>Lazy sync<CR>"),
				dashboard.button("q", "Quit", "<cmd>qa<CR>"),
			},
			position = "center",
		}

		theta.config = {
			layout = {
				{ type = "padding", val = 2 },
				header,
				{ type = "padding", val = 2 },
				section_mru,
				{ type = "padding", val = 2 },
				buttons,
			},
			opts = {
				margin = 5,
				setup = function()
					vim.api.nvim_create_autocmd("DirChanged", {
						pattern = "*",
						group = "alpha_temp",
						callback = function()
							require("alpha").redraw()
							vim.cmd("AlphaRemap")
						end,
					})
				end,
			},
		}

		alpha.setup(theta.config)
	end,
}
