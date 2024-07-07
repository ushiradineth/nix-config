return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require "telescope.builtin"
      vim.keymap.set("n", "<D-p>", builtin.find_files, { noremap = true, silent = true })
      vim.keymap.set("n", "<D-f>", builtin.live_grep, { noremap = true, silent = true })
      vim.keymap.set(
        "n",
        "<D-F>",
        require("telescope").extensions.live_grep_args.live_grep_args,
        { noremap = true, silent = true }
      )
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
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    version = "^1.0.0",
    config = function() require("telescope").load_extension "live_grep_args" end,
  },
}
