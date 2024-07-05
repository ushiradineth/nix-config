return {
  "romgrk/barbar.nvim",
  dependencies = {
    "lewis6991/gitsigns.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    vim.g.barbar_auto_setup = false
    local map = vim.api.nvim_set_keymap
    local opts = { noremap = true, silent = true }

    -- Move to previous/next
    map("n", "<C-,>", "<Cmd>BufferPrevious<CR>", opts)
    map("n", "<C-.>", "<Cmd>BufferNext<CR>", opts)

    -- Goto buffer in position...
    map("n", "<C-1>", "<Cmd>BufferGoto 1<CR>", opts)
    map("n", "<C-2>", "<Cmd>BufferGoto 2<CR>", opts)
    map("n", "<C-3>", "<Cmd>BufferGoto 3<CR>", opts)
    map("n", "<C-4>", "<Cmd>BufferGoto 4<CR>", opts)
    map("n", "<C-5>", "<Cmd>BufferGoto 5<CR>", opts)
    map("n", "<C-6>", "<Cmd>BufferGoto 6<CR>", opts)
    map("n", "<C-7>", "<Cmd>BufferGoto 7<CR>", opts)
    map("n", "<C-8>", "<Cmd>BufferGoto 8<CR>", opts)
    map("n", "<C-9>", "<Cmd>BufferGoto 9<CR>", opts)

    -- Close buffer
    map("n", "<C-c>", "<Cmd>BufferClose<CR>", opts)
    map("n", "<C-x>", "<Cmd>BufferClose<CR>", opts)

    -- Restore buffer
    map("n", "<C-t>", "<Cmd>BufferRestore<CR>", opts)

    require("barbar").setup {
      animation = false,
      sidebar_filetypes = {
        ["neo-tree"] = true,
      },
    }
  end,
  version = "^1.0.0",
}
