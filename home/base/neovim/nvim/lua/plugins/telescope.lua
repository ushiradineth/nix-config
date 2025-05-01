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
		vim.keymap.set(
			"n",
			"<leader>sa",
			telescope.extensions.live_grep_args.live_grep_args,
			{ noremap = true, silent = true, desc = "Search all files in current working directory" }
		)
		vim.keymap.set(
			"n",
			"<leader>sc",
			builtin.current_buffer_fuzzy_find,
			{ noremap = true, silent = true, desc = "Fuzzy search in current file" }
		)

		vim.keymap.set(
			"n",
			"<leader>swb",
			live_grep_args_shortcuts.grep_word_under_cursor_current_buffer,
			{ noremap = true, silent = true, desc = "Fuzzy search the word under cursor in current file" }
		)

		vim.keymap.set("n", "<leader>swa", live_grep_args_shortcuts.grep_word_under_cursor, {
			noremap = true,
			silent = true,
			desc = "Fuzzy search the word under cursor in current working directory",
		})

		vim.keymap.set("n", "<leader>ss", require("telescope.builtin").resume, {
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
							["<C-t>"] = lga_actions.quote_prompt({ postfix = " -t tf" }),
							["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob **/*.tf" }),
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
