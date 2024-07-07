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

-- Quit
vim.keymap.set("n", "<leader>qq", ":qa!<CR>", { noremap = true, silent = true, desc = "Force Quit" })
vim.keymap.set("n", "<leader>wq", ":wq!<CR>", { noremap = true, silent = true, desc = "Save and Quit" })
vim.keymap.set("n", "<leader>w", ":silent w<CR>", { noremap = true, silent = true, desc = "Save" })
