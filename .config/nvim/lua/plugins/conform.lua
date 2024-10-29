return {
	{
		"nvimtools/none-ls.nvim",
		dependencies = {
			"nvimtools/none-ls-extras.nvim",
		},
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					require("none-ls.diagnostics.eslint_d").with({
						diagnostics_format = "[eslint] #{m}\n(#{c})",
					}),
				},
			})
		end,
	},
	{
		"jay-babu/mason-null-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"nvimtools/none-ls.nvim",
		},
		config = function()
			require("mason-null-ls").setup({
				ensure_installed = {
					"stylua",
					"yamllint",
					"tfsec",
					"sqlfluff",
					"rustywind",
					"sqlfmt",
					"prettier",
					"hclfmt",
					"golines",
					"golangci-lint-langserver",
					"goimports-reviser",
					"golangci-lint",
					"goimports",
					"gofumpt",
					"checkmake",
					"beautysh",
					"bash-debug-adapter",
					"ansible-lint",
					"autopep8",
					"jsonlint",
					"markdownlint",
					"sonarlint-language-server",
					"yaml-language-server",
					"codespell",
					"nixfmt",
					"markdownfmt",
				},
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		event = "LspAttach",
		opts = {
			quiet = true,
			formatters_by_ft = {
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				markdown = { "prettier" },
				yaml = { "prettier" },
				graphql = { "prettier" },
				vue = { "prettier" },
				angular = { "prettier" },
				less = { "prettier" },
				flow = { "prettier" },
				sh = { "beautysh" },
				bash = { "beautysh" },
				zsh = { "beautysh" },
				nix = { "nixfmt" },
				go = { "goimports", "gofmt" },
				hcl = { "hclfmt" },
				lua = { "stylua" },
				["*"] = { "codespell" },
				["_"] = { "trim_whitespace" },
				md = { "markdownlint", "markdownfmt" },
			},
			default_format_opts = {
				lsp_format = "fallback",
			},
			notify_on_error = true,
			notify_no_formatters = true,
			format_on_save = function(bufnr)
				-- Disable autoformat for files in a certain path
				local bufname = vim.api.nvim_buf_get_name(bufnr)
				if bufname:match("/node_modules/") then
					return
				end

				return { timeout_ms = 1000, lsp_fallback = true }
			end,
			format_after_save = { lsp_fallback = true },
		},
		config = function(_, opts)
			local conform = require("conform")
			conform.setup(opts)

			vim.keymap.set("n", "<leader>cf", function()
				conform.format({ async = true, lsp_fallback = true })
			end, { noremap = true, silent = true, desc = "Format" })

			-- Customize prettier args
			require("conform.formatters.prettier").args = function(_, ctx)
				local prettier_roots = { ".prettierrc", ".prettierrc.json", "prettier.config.js" }
				local args = { "--stdin-filepath", "$FILENAME" }
				local config_path = vim.fn.stdpath("config")

				local localPrettierConfig = vim.fs.find(prettier_roots, {
					upward = true,
					path = ctx.dirname,
					type = "file",
				})[1]
				local globalPrettierConfig = vim.fs.find(prettier_roots, {
					path = type(config_path) == "string" and config_path or config_path[1],
					type = "file",
				})[1]
				local disableGlobalPrettierConfig = os.getenv("DISABLE_GLOBAL_PRETTIER_CONFIG")

				-- Project config takes precedence over global config
				if localPrettierConfig then
					vim.list_extend(args, { "--config", localPrettierConfig })
				elseif globalPrettierConfig and not disableGlobalPrettierConfig then
					vim.list_extend(args, { "--config", globalPrettierConfig })
				end

				local hasTailwindPrettierPlugin = vim.fs.find("node_modules/prettier-plugin-tailwindcss", {
					upward = true,
					path = ctx.dirname,
					type = "directory",
				})[1]

				if hasTailwindPrettierPlugin then
					vim.list_extend(args, { "--plugin", "prettier-plugin-tailwindcss" })
				end

				local hasOrganizeImportsPrettierPlugin = vim.fs.find("node_modules/prettier-plugin-organize-imports", {
					upward = true,
					path = ctx.dirname,
					type = "directory",
				})[1]

				if hasOrganizeImportsPrettierPlugin then
					vim.list_extend(args, { "--plugin", "prettier-plugin-organize-imports" })
				end

				return args
			end

			conform.formatters.beautysh = {
				prepend_args = function()
					return { "--indent-size", "2", "--force-function-style", "fnpar" }
				end,
			}
		end,
	},
}