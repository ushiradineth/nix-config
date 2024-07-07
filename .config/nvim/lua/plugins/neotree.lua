return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    "3rd/image.nvim",
  },
  config = function()
    require("neo-tree").setup {
      filesystem = {
        hijack_netrw_behavior = "open_current",
        filtered_items = {
          visible = true,
          hide_dotfiles = true,
          hide_gitignored = true,
        },
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
      },
      event_handlers = {
        {
          event = "file_opened",
          handler = function() require("neo-tree").close_all() end,
        },
      },
      window = {
        mappings = {
          ["P"] = { "toggle_preview", config = { use_float = false, use_image_nvim = true } },
        },
      },
    }

    vim.keymap.set(
      "n",
      "<leader>e",
      ":Neotree filesystem toggle left<CR>",
      { noremap = true, silent = true, desc = "Toggle Neotree" }
    )
    vim.keymap.set("n", "<C-f>", ":Neotree<CR>", { noremap = true, silent = true })
  end,
}
