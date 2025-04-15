return {
	{
		-- DIRECTORY EDITOR
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "-", "<cmd>Oil<CR>", desc = "Explorer" },
		},
		opts = {
			view_options = {
				show_hidden = true,
			},
		},
	},
	-- {
	--  -- FILE EXPLORER
	-- 	"nvim-neo-tree/neo-tree.nvim",
	-- 	branch = "v3.x",
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"nvim-tree/nvim-web-devicons",
	-- 		"MunifTanjim/nui.nvim",
	-- 		"3rd/image.nvim",
	-- 	},
	-- 	config = function()
	-- 		require("neo-tree").setup({
	-- 			close_if_last_window = true,
	-- 			use_popups_for_input = false,
	-- 			filesystem = {
	-- 				hijack_netrw_behavior = "open_current",
	-- 				filtered_items = {
	-- 					visible = true, -- show filtered items but with a faded style
	-- 					hide_dotfiles = true,
	-- 					hide_gitignored = true,
	-- 				},
	-- 				never_show = { -- remains hidden even if visible is toggled to true
	-- 					".DS_Store",
	-- 					"thumbs.db",
	-- 				},
	-- 				follow_current_file = {
	-- 					enabled = true,
	-- 					leave_dirs_open = false,
	-- 				},
	-- 			},
	-- 			event_handlers = {
	-- 				{
	-- 					event = "file_opened",
	-- 					handler = function()
	-- 						require("neo-tree").close_all()
	-- 					end,
	-- 				},
	-- 			},
	-- 			window = {
	-- 				mappings = {
	-- 					["P"] = { "toggle_preview", config = { use_float = false, use_image_nvim = true } },
	-- 				},
	-- 			},
	-- 		})
	--
	-- 		vim.keymap.set(
	-- 			"n",
	-- 			"<leader>e",
	-- 			":Neotree filesystem toggle left<CR>",
	-- 			{ noremap = true, silent = true, desc = "Toggle Neotree" }
	-- 		)
	-- 	end,
	-- },
}
