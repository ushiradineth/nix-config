vim.cmd("set expandtab") -- Use spaces instead of tabs
vim.cmd("set tabstop=2") -- Number of spaces that a <Tab> in the file counts for
vim.cmd("set softtabstop=2") -- Number of spaces that a <Tab> counts for while editing
vim.cmd("set shiftwidth=2") -- Number of spaces to use for each step of (auto)indent
vim.cmd("set noshowmode") -- Hide the mode display (e.g., --INSERT--)
vim.cmd("set noshowcmd") -- Hide the display of the last command in the command line
vim.cmd("set shortmess+=F") -- Don't display "File is in read-only mode" message when opening a read-only file
vim.cmd("set fillchars+=vert:▕") -- Use a single vertical bar for vertical split separators
vim.cmd("set nohlsearch") -- Disable search highlight
vim.cmd("cnoreabbrev w silent! write") -- :w is always silent

vim.api.nvim_set_option("clipboard", "unnamed") -- Use the system clipboard for all operations
vim.g.mapleader = " " -- Set the leader key to space
vim.g.maplocalleader = "\\" -- Set the local leader key to backslash
vim.opt.laststatus = 3 -- Global statusline
vim.wo.number = true -- Enable line numbers in the window
vim.keymap.set("n", "f", "w") -- Map 'f' to move to the next word
-- Set up key mapping in normal mode
vim.api.nvim_set_keymap("n", "<leader>/", "gcc", { noremap = false, silent = true, desc = "Toggle Comment" })

-- Set up key mapping in visual mode
vim.api.nvim_set_keymap("v", "<leader>/", "gc", { noremap = false, silent = true, desc = "Toggle Comment" })

vim.keymap.set(
	"n",
	"<leader>lr",
	":lua vim.wo.relativenumber = not vim.wo.relativenumber; vim.wo.number = true<CR>",
	{ noremap = true, silent = true, desc = "Toggle Relative Line Number" }
)
vim.keymap.set(
	"n",
	"<leader>lt",
	":lua vim.wo.number = not vim.wo.number; vim.wo.relativenumber = false<CR>",
	{ noremap = true, silent = true, desc = "Toggle Line Number" }
)

vim.keymap.set("n", "<leader>tw", ":set wrap!<CR>", { noremap = true, silent = true, desc = "Toggle Wrap" })

-- Quit
vim.keymap.set("n", "<leader>qq", ":qa!<CR>", { noremap = true, silent = true, desc = "Force Quit" })
vim.keymap.set("n", "<leader>wq", ":wq!<CR>", { noremap = true, silent = true, desc = "Save and Quit" })
vim.keymap.set("n", "<leader>w", ":silent w<CR>", { noremap = true, silent = true, desc = "Save" })

vim.filetype.add({
	extension = {
		mdx = "mdx",
	},
})

vim.filetype.add({
	pattern = {
		[".*/templates/.*%.yaml"] = "helm",
	},
})
