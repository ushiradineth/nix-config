return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require "telescope.builtin"
      vim.keymap.set("n", "<D-p>", builtin.find_files, {})
      vim.keymap.set("n", "<D-f>", builtin.live_grep, {})
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup {
        pickers = {
          find_files = {
            hidden = true,
            file_ignore_patterns = { ".git/", ".nuxt", ".next", "node_modules/*" },
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
              -- even more opts
            },
          },
        },
      }

      require("telescope").load_extension "ui-select"
    end,
  },
}
