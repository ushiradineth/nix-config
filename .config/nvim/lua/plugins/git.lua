return {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup {
        current_line_blame = true,
      }

      vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", { desc = "Preview Hunk" })
    end,
  },
  {
    "tpope/vim-fugitive",
  },
}
