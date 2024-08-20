return {
  { -- START SCREEN
    "goolord/alpha-nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },

    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.startify")

      dashboard.section.header.val = {
        [[                                                                       ]],
        [[                                                                       ]],
        [[                                                                       ]],
        [[                                                                       ]],
        [[                                                                     ]],
        [[       ████ ██████           █████      ██                     ]],
        [[      ███████████             █████                             ]],
        [[      █████████ ███████████████████ ███   ███████████   ]],
        [[     █████████  ███    █████████████ █████ ██████████████   ]],
        [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
        [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
        [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
        [[                                                                       ]],
        [[                                                                       ]],
        [[                                                                       ]],
      }

      alpha.setup(dashboard.opts)
    end,
  },
  { -- FILE EXPLORER
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "3rd/image.nvim",
    },
    config = function()
      require("neo-tree").setup({
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
            handler = function()
              require("neo-tree").close_all()
            end,
          },
        },
        window = {
          mappings = {
            ["P"] = { "toggle_preview", config = { use_float = false, use_image_nvim = true } },
          },
        },
      })

      vim.keymap.set(
        "n",
        "<leader>e",
        ":Neotree filesystem toggle left<CR>",
        { noremap = true, silent = true, desc = "Toggle Neotree" }
      )
      vim.keymap.set("n", "<C-f>", ":Neotree<CR>", { noremap = true, silent = true })
    end,
  },
  {
    -- WINDOW TAB BAR
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

      require("barbar").setup({
        animation = false,
        sidebar_filetypes = {
          ["neo-tree"] = true,
        },
      })
    end,
    version = "^1.0.0",
  },
  { -- UI TRANSPARENCY
    "xiyaowong/transparent.nvim",
    config = function()
      require("transparent").setup({
        extra_groups = {},
      })

      vim.keymap.set(
        "n",
        "<Leader>t",
        ":TransparentToggle<CR>",
        { noremap = true, silent = true, desc = "Toggle Transparency" }
      )
    end,
  },
}
