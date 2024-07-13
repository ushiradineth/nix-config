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
        defaults = {
          layout_strategy = "vertical",
          layout_config = { height = 0.75 },
          scroll_strategy = "limit",
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
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
  {
    -- SEARCH NOTES/TODOS IN TELESCOPE
    "folke/todo-comments.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup {
        keywords = {
          WARN = {
            icon = " ",
            color = "warning",
            alt = { "WARNING", "IMPORTANT" },
          },
        },
        highlight = {
          pattern = [[.*<((KEYWORDS)%(\(.{-1,}\))?):]], -- supports both `TODO:` and `TODO(name):`
        },
        search = {
          pattern = [[\b(KEYWORDS)(\(\w*\))*:]], -- ripgrep regex, supporting the pattern TODO(name):
        },
      }
    end,
  },
  {
    -- SEARCH INDEXER
    "kevinhwang91/nvim-hlslens",
    config = true,
  },
  {
    -- IMPROVES ASTERISK BEHAVIOR
    "haya14busa/vim-asterisk",
    config = function()
      vim.keymap.set("n", "*", [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>]], {})
      vim.keymap.set("n", "#", [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>]], {})
      vim.keymap.set("n", "g*", [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>]], {})
      vim.keymap.set("n", "g#", [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>]], {})

      vim.keymap.set("x", "*", [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>]], {})
      vim.keymap.set("x", "#", [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>]], {})
      vim.keymap.set("x", "g*", [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>]], {})
      vim.keymap.set("x", "g#", [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>]], {})
    end,
  },
}
