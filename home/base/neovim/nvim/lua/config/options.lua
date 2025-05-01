vim.g.mapleader = " " -- Set the leader key to space
vim.g.maplocalleader = "\\" -- Set the local leader key to backslash

vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 2 -- A <Tab> in a file = 2 spaces
vim.opt.softtabstop = 2 -- A <Tab> when editing = 2 spaces
vim.opt.shiftwidth = 2 -- Auto-indent uses 2 spaces

vim.opt.laststatus = 3 -- Global statusline
vim.opt.shortmess = vim.opt.shortmess + { c = true } -- Prevents verbose messages when using completion.
vim.wo.number = true -- Enable line numbers in the window

vim.cmd("set noshowmode") -- Hide the mode display (e.g., --INSERT--)
vim.cmd("set noshowcmd") -- Hide the display of the last command in the command line
vim.cmd("set shortmess+=F") -- Don't display "File is in read-only mode" message when opening a read-only file
vim.cmd("set fillchars+=vert:▕") -- Use a single vertical bar for vertical split separators
vim.cmd("set nohlsearch") -- Disable search highlight
vim.cmd("set signcolumn=yes") -- Prevents the UI from shifting when diagnostics or git signs appear.
vim.cmd("cnoreabbrev w silent! write") -- :w is always silent

vim.api.nvim_set_option("clipboard", "unnamedplus") -- Use the system clipboard for all operations
vim.api.nvim_set_option("updatetime", 300) -- Makes cursor-hover actions (like diagnostics popups) respond faster.

vim.lsp.set_log_level("error") -- Disable logging
