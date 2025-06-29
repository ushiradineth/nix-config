local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Cmd+Left / Cmd+Right as Ctrl-A / Ctrl-E
-- Skip to start or end of line
map({ "n", "v" }, "<C-a>", "^", opts)
map({ "n", "v" }, "<C-e>", "$", opts)
map("i", "<C-a>", "<C-o>^", opts)
map("i", "<C-e>", "<C-o>$", opts)

-- Opt+Left / Opt+Right as ESC b / ESC f
-- Skip to start or end of word
map({ "n", "v" }, "<Esc>b", "b", opts)
map({ "n", "v" }, "<Esc>f", "w", opts)
map("i", "<Esc>b", "<C-o>b", opts)
map("i", "<Esc>f", "<C-o>w", opts)

-- Ctrl+Left / Ctrl+Right
-- Skip to start or end of WORD
map({ "n", "v" }, "\27[1;5D", "B", opts)
map({ "n", "v" }, "\27[1;5C", "W", opts)
map("i", "\27[1;5D", "<C-o>B", opts)
map("i", "\27[1;5C", "<C-o>W", opts)
