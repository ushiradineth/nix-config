return {
	{
		-- QUICK OPEN `%s//gcI`
		"roobert/search-replace.nvim",
		config = function()
			vim.api.nvim_set_keymap(
				"v",
				"<C-r>",
				"<CMD>SearchReplaceWithinVisualSelection<CR>",
				{ noremap = true, silent = true }
			)

			vim.api.nvim_set_keymap(
				"n",
				"<leader>rr",
				"<CMD>SearchReplaceSingleBufferOpen<CR>",
				{ noremap = true, silent = true, desc = "Base replace" }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>rw",
				"<CMD>SearchReplaceSingleBufferCWord<CR>",
				{ noremap = true, silent = true, desc = "Replace hover word" }
			)

			-- show the effects of a search / replace in a live preview window
			vim.o.inccommand = "split"

			require("search-replace").setup({
				default_replace_single_buffer_options = "gcI",
			})
		end,
	},
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
					enable_close = true, -- Auto close tags
					enable_rename = true, -- Auto rename pairs of tags
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
		-- DIAGNOSTICS
		"folke/trouble.nvim",
		opts = {},
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
	{
		-- AI CODE COMPLETION
		"supermaven-inc/supermaven-nvim",
		config = function()
			require("supermaven-nvim").setup({
				log_level = "off",
			})
		end,
	},
	-- { -- COPILOT
	-- 	"github/copilot.vim",
	-- },
	{
		-- TIME TRACKING
		"wakatime/vim-wakatime",
		lazy = false,
	},
	{
		-- Markdown Preview
		"OXY2DEV/markview.nvim",
		lazy = false,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			vim.keymap.set(
				"n",
				"<Leader>tm",
				":Markview toggleAll<CR>",
				{ noremap = true, silent = true, desc = "Toggle Markdown Preview" }
			)
		end,
	},
}
