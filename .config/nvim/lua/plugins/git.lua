toggle_diff = function(cmd)
	local lib = require("diffview.lib")
	local view = lib.get_current_view()

	if view then
		vim.cmd("DiffviewClose")
	else
		vim.cmd(cmd)
	end
end

return {
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				current_line_blame = true,
			})

			vim.keymap.set(
				"n",
				"<leader>gp",
				":Gitsigns preview_hunk<CR>",
				{ noremap = true, silent = true, desc = "Preview Hunk" }
			)
		end,
	},
	{
		"tpope/vim-fugitive",
	},
	{
		"sindrets/diffview.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			vim.keymap.set(
				"n",
				"<leader>gd",
				":lua toggle_diff('DiffviewOpen -- %')<CR>",
				{ noremap = true, silent = true, desc = "Diff" }
			)
			vim.keymap.set(
				"n",
				"<leader>grd",
				":lua toggle_diff('DiffviewOpen')<CR>",
				{ noremap = true, silent = true, desc = "Repo Diff" }
			)
			vim.keymap.set(
				"n",
				"<leader>gh",
				":lua toggle_diff('DiffviewFileHistory %')<CR>",
				{ noremap = true, silent = true, desc = "History" }
			)
			vim.keymap.set(
				"n",
				"<leader>grh",
				":lua toggle_diff('DiffviewFileHistory')<CR>",
				{ noremap = true, silent = true, desc = "Repo History" }
			)

			require("diffview").setup({})
		end,
	},
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
		},
		keys = {
			{ "<leader>gl", "<cmd>LazyGit<cr>", desc = "LazyGit" },
		},
	},
}
