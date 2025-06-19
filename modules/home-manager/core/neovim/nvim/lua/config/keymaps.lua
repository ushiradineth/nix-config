-- Comment
vim.api.nvim_set_keymap("n", "<leader>/", "gcc", { noremap = false, silent = true, desc = "Toggle Comment" })
vim.api.nvim_set_keymap("v", "<leader>/", "gc", { noremap = false, silent = true, desc = "Toggle Comment" })

-- Quit
vim.keymap.set("n", "<leader>qq", ":qa!<CR>", { noremap = true, silent = true, desc = "Force Quit" })
vim.keymap.set("n", "<leader>wq", ":wq!<CR>", { noremap = true, silent = true, desc = "Save and Quit" })
vim.keymap.set("n", "<leader>w", ":silent w<CR>", { noremap = true, silent = true, desc = "Save" })

-- Casing
vim.keymap.set("v", "<leader>cc", [[:s/\v_(\w)/\U\1/g<CR>:s/\v(^\l)/\L\1/<CR>]], { desc = "snake_case to camel_case" })
vim.keymap.set(
	"v",
	"<leader>cs",
	[[:s/\v(\l)(\u)/\1_\l\2/g<CR>:s/\v(^\l)/\L\1/g<CR>]],
	{ desc = "camelCase to snake_case" }
)

-- Misc
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

vim.keymap.set(
	"n",
	"<Leader>lc",
	":let @+ = expand('%') . ':' . line('.')<cr>",
	{ noremap = true, silent = true, desc = "Copy file name and the line number" }
)

vim.keymap.set("n", "<leader>cw", ":set wrap!<CR>", { noremap = true, silent = true, desc = "Code Wrap" })

vim.keymap.set("n", "<leader>dc", function()
	vim.diagnostic.open_float(nil, { focusable = false })
end, { noremap = true, silent = true, desc = "Current Line Diagnostics" })
