return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
    "nvim-telescope/telescope-ui-select.nvim",
    "nvim-telescope/telescope-live-grep-args.nvim",
  },

  config = function()
    local builtin = require("telescope.builtin")
    local telescope = require("telescope")
    local lga_actions = require("telescope-live-grep-args.actions")
    local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")

    vim.keymap.set("n", "<D-p>", builtin.find_files, { noremap = true, silent = true, desc = "Search files" })

    -- Initiate search in all files in the current working directory
    vim.keymap.set(
      "n",
      "<leader>sa",
      telescope.extensions.live_grep_args.live_grep_args,
      { noremap = true, silent = true, desc = "Working directory" }
    )

    -- Initiate search for the word under the cursor in the working directory
    vim.keymap.set("n", "<leader>swa", live_grep_args_shortcuts.grep_word_under_cursor, {
      noremap = true,
      silent = true,
      desc = "Working Directory",
    })

    -- Initiate search in the current file
    vim.keymap.set(
      "n",
      "<leader>sc",
      builtin.current_buffer_fuzzy_find,
      { noremap = true, silent = true, desc = "Current Buffer" }
    )

    -- Initiate search for the word under the cursor in the current buffer
    vim.keymap.set(
      "n",
      "<leader>swc",
      live_grep_args_shortcuts.grep_word_under_cursor_current_buffer,
      { noremap = true, silent = true, desc = "Current Buffer" }
    )

    -- Initiate search in all symbols exposed by the LSP
    vim.keymap.set(
      "n",
      "<leader>st",
      builtin.lsp_workspace_symbols,
      { noremap = true, silent = true, desc = "All symbols" }
    )

    -- List the current file's git history
    vim.keymap.set(
      "n",
      "<leader>gc",
      builtin.git_bcommits,
      { noremap = true, silent = true, desc = "Commits" }
    )

    -- List the current git repository's history
    vim.keymap.set(
      "n",
      "<leader>grc",
      builtin.git_commits,
      { noremap = true, silent = true, desc = "Commits" }
    )

    -- List the changed files in the current git repository
    vim.keymap.set(
      "n",
      "<leader>gs",
      builtin.git_status,
      { noremap = true, silent = true, desc = "Changes" }
    )

    -- Resume the last search
    vim.keymap.set("n", "<leader>ss", builtin.resume, {
      noremap = true,
      silent = true,
      desc = "Resume",
    })

    local ignore_patterns = {
      ".git",
      "node_modules",
      ".next",
      ".nuxt",
      "dist",
      "build",
      "target",
      "*-lock.yaml",
      "*-lock.json",
      "*.tfvars",
      ".direnv",
    }

    telescope.setup({
      pickers = {
        find_files = {
          hidden = true,
          file_ignore_patterns = ignore_patterns,
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
        live_grep_args = {
          auto_quoting = true,
          mappings = {
            i = {
              ["<C-t>"] = lga_actions.quote_prompt({ postfix = " -t rs" }),
              ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob **/*.rs" }),
            },
          },
        },
      },
      defaults = {
        layout_strategy = "vertical",
        layout_config = {
          horizontal = {
            size = {
              width = "90%",
              height = "60%",
            },
          },
          vertical = {
            size = {
              width = "90%",
              height = "90%",
            },
          },
          width = 0.9,
          height = 0.9,
        },
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
          "--trim",
          "--ignore-file",
          ".gitignore",
        },
        file_ignore_patterns = ignore_patterns,
      },
    })

    telescope.load_extension("ui-select")
    telescope.load_extension("fzf")
    telescope.load_extension("live_grep_args")
  end,
}
