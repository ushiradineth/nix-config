--- Hide Lualine when in command mode
---
vim.api.nvim_create_autocmd("CmdlineEnter", {
	callback = function()
		require("lualine").hide()
	end,
})

--- Unhide Lualine when out of command mode
vim.api.nvim_create_autocmd("CmdlineLeave", {
	callback = function()
		require("lualine").hide({ unhide = true })
	end,
})

return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")
		local function get_hl_color(group, attr)
			-- 1) Try Neovim’s native API (0.9+):
			local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
			if ok and hl[attr] then
				return string.format("#%06x", hl[attr])
			end
			-- 2) Fallback to the synIDattr route:
			local id = vim.fn.synIDtrans(vim.fn.hlID(group))
			local what = (attr == "fg" and "fg#" or "bg#")
			local col = vim.fn.synIDattr(id, what)
			return (col ~= "" and col) or nil
		end
		local colors = {
			bg = get_hl_color("Normal", "bg"),
			fg = get_hl_color("Normal", "fg"),
			yellow = get_hl_color("WarningMsg", "fg"),
			cyan = get_hl_color("Type", "fg"),
			green = get_hl_color("String", "fg"),
			orange = get_hl_color("Conditional", "fg"),
			violet = get_hl_color("Constant", "fg"),
			magenta = get_hl_color("Identifier", "fg"),
			blue = get_hl_color("Function", "fg"),
			red = get_hl_color("Error", "fg"),
		}

		-- -- Color table for highlights
		-- local colors = {
		-- 	bg = "#202328",
		-- 	fg = "#bbc2cf",
		-- 	yellow = "#ECBE7B",
		-- 	cyan = "#008080",
		-- 	darkblue = "#081633",
		-- 	green = "#98be65",
		-- 	orange = "#FF8800",
		-- 	violet = "#a9a1e1",
		-- 	magenta = "#c678dd",
		-- 	blue = "#51afef",
		-- 	red = "#ec5f67",
		-- }

		local conditions = {
			buffer_not_empty = function()
				return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
			end,
			hide_in_width = function()
				return vim.fn.winwidth(0) > 80
			end,
		}

		local oil = {
			sections = {
				lualine_a = {
					{
						function()
							local ok, o = pcall(require, "oil")
							if ok then
								return vim.fn.fnamemodify(o.get_current_dir(), ":~")
							else
								return ""
							end
						end,
						color = { fg = colors.magenta, gui = "bold" },
					},
				},
			},
			filetypes = { "oil" },
		}

		-- Config
		local config = {
			options = {
				-- Disable sections and component separators
				component_separators = "",
				section_separators = "",
				theme = "auto",
			},
			sections = {
				-- these are to remove the defaults
				lualine_a = {},
				lualine_b = {},
				lualine_y = {},
				lualine_z = {},
				-- These will be filled later
				lualine_c = {},
				lualine_x = {},
			},
			inactive_sections = {
				-- these are to remove the defaults
				lualine_a = {},
				lualine_b = {},
				lualine_y = {},
				lualine_z = {},
				lualine_c = {},
				lualine_x = {},
			},
			extensions = { oil, "mason", "lazy", "trouble" },
		}

		-- Inserts a component in lualine_c at left section
		local function ins_left(component)
			table.insert(config.sections.lualine_c, component)
		end

		-- Inserts a component in lualine_x at right section
		local function ins_right(component)
			table.insert(config.sections.lualine_x, component)
		end

		ins_left({
			"mode",
			cond = conditions.buffer_not_empty,
		})

		ins_left({
			"filename",
			cond = conditions.buffer_not_empty,
			color = { fg = colors.magenta, gui = "bold" },
			path = 1,
		})

		ins_left({
			"diagnostics",
			cond = conditions.buffer_not_empty,
			sources = { "nvim_diagnostic" },
			symbols = { error = " ", warn = " ", info = " " },
			diagnostics_color = {
				color_error = { fg = colors.red },
				color_warn = { fg = colors.yellow },
				color_info = { fg = colors.cyan },
			},
		})

		ins_left({
			function()
				local reg = vim.fn.reg_recording()
				if reg ~= "" then
					return "Recording @" .. reg
				end
				return ""
			end,
		})

		-- Gap between left and right sections
		ins_left({
			function()
				return "%="
			end,
		})

		ins_right({
			"lsp_status",
			ignore_lsp = { "diagnosticls", "typos_lsp" },
			icon = "",
			symbols = {
				done = "",
			},
		})

		ins_right({
			"diff",
			cond = conditions.hide_in_width,
			symbols = { added = " ", modified = "󰝤 ", removed = " " },
			diff_color = {
				added = { fg = colors.green },
				modified = { fg = colors.orange },
				removed = { fg = colors.red },
			},
		})

		ins_right({
			"branch",
			color = { fg = colors.violet, gui = "bold" },
			icon = "",
		})

		lualine.setup(config)
	end,
}
