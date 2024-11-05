return {
	{ -- SEARCH
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
			"nvim-telescope/telescope-ui-select.nvim",
		},

		config = function()
			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<D-p>", builtin.find_files, { noremap = true, silent = true, desc = "Search files" })
			vim.keymap.set(
				"n",
				"<leader>sa",
				builtin.live_grep,
				{ noremap = true, silent = true, desc = "Search all files in current working directory" }
			)
			vim.keymap.set(
				"n",
				"<leader>sc",
				builtin.current_buffer_fuzzy_find,
				{ noremap = true, silent = true, desc = "Fuzzy search in current file" }
			)

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

			require("telescope").setup({
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

			require("telescope").load_extension("ui-select")
			require("telescope").load_extension("fzf")
		end,
	},
	{ -- UI FOR TELESCOPE
		"nvim-telescope/telescope-ui-select.nvim",
	},
}
