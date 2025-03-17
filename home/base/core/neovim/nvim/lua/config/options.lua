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
vim.lsp.set_log_level("error") -- Disable logging
