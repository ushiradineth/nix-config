vim.cmd "set expandtab" -- Use spaces instead of tabs
vim.cmd "set tabstop=2" -- Number of spaces that a <Tab> in the file counts for
vim.cmd "set softtabstop=2" -- Number of spaces that a <Tab> counts for while editing
vim.cmd "set shiftwidth=2" -- Number of spaces to use for each step of (auto)indent
vim.cmd "set noshowmode" -- Hide the mode display (e.g., --INSERT--)
vim.cmd "set noshowcmd" -- Hide the display of the last command in the command line
vim.cmd "set shortmess+=F" -- Don't display "File is in read-only mode" message when opening a read-only file
vim.cmd "set fillchars+=vert:▕" -- Use a single vertical bar for vertical split separators
vim.cmd "set nohlsearch" -- Disable search highlight

vim.api.nvim_set_option("clipboard", "unnamed") -- Use the system clipboard for all operations
vim.g.mapleader = " " -- Set the leader key to space
vim.g.maplocalleader = "\\" -- Set the local leader key to backslash
vim.opt.laststatus = 3 -- Global statusline
vim.wo.number = true -- Enable line numbers in the window

vim.keymap.set({ "n", "x", "o" }, "<Leader>/", "gcc", { noremap = true, silent = true, desc = "Toggle Comment" })
vim.keymap.set(
  "n",
  "<Leader>t",
  ":TransparentToggle<CR>",
  { noremap = true, silent = true, desc = "Toggle Transparency" }
)
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

-- Move code
vim.keymap.set("n", "<A-j>", ":MoveLine(1)<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-k>", ":MoveLine(-1)<CR>", { noremap = true, silent = true })
vim.keymap.set("v", "<A-j>", ":MoveBlock(1)<CR>", { noremap = true, silent = true })
vim.keymap.set("v", "<A-k>", ":MoveBlock(-1)<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-Down>", ":MoveLine(1)<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-Up>", ":MoveLine(-1)<CR>", { noremap = true, silent = true })
vim.keymap.set("v", "<A-Down>", ":MoveBlock(1)<CR>", { noremap = true, silent = true })
vim.keymap.set("v", "<A-Up>", ":MoveBlock(-1)<CR>", { noremap = true, silent = true })
