local function merge(t1, t2)
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
	return t1
end

local function mappings(bufnr)
	local opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, merge({ desc = "Go to Definition" }, opts))
	vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, merge({ desc = "Code Action" }, opts))
	vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, merge({ desc = "Rename Definition" }, opts))
end

local generic_setup = function(server_name)
	require("lspconfig")[server_name].setup({
		on_attach = function(_, bufnr)
			mappings(bufnr)
		end,
	})
end

local custom_servers = {
	["eslint"] = function()
		require("lspconfig").eslint.setup({
			on_attach = function(_, bufnr)
				mappings(bufnr)

				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					command = "EslintFixAll",
				})
			end,
			settings = {
				workingDirectory = { mode = "location" },
			},
			root_dir = require("lspconfig").util.find_git_ancestor,
		})
	end,
	["yamlls"] = function()
		require("lspconfig").yamlls.setup({
			on_attach = function(_, bufnr)
				if vim.bo[bufnr].filetype == "helm" then
					vim.schedule(function()
						vim.cmd("LspStop ++force yamlls")
					end)
				end

				mappings(bufnr)
			end,
			settings = {
				yaml = {
					schemas = {
						kubernetes = "*.yaml",
						["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/**/*.{yml,yaml}",
						["http://json.schemastore.org/circleciconfig"] = ".circleci/**/*.{yml,yaml}",
						["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
						["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
						["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
						["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
						["http://json.schemastore.org/ansible-playbook"] = "*play*.{yml,yaml}",
						["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
						["https://json.schemastore.org/dependabot-v2"] = ".github/dependabot.{yml,yaml}",
						["https://json.schemastore.org/gitlab-ci"] = "*gitlab-ci*.{yml,yaml}",
						["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] = "*api*.{yml,yaml}",
						["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*docker-compose*.{yml,yaml}",
						["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = "*flow*.{yml,yaml}",
						["https://api.bitbucket.org/schemas/pipelines-configuration"] = "*bitbucket-pipelines*.{yml,yaml}",
						["values.schema.json"] = "values.yaml",
					},
				},
			},
		})
	end,
	["helm-ls"] = function()
		require("lspconfig").helm_ls.setup({
			on_attach = function(_, bufnr)
				mappings(bufnr)
			end,
			settings = {
				["helm-ls"] = {
					path = "yaml-language-server",
				},
			},
		})
	end,
}

return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "mason.nvim", "treesitter-terraform-doc.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"typos_lsp",
					"ansiblels",
					"astro",
					"bashls",
					"cmake",
					"cssls",
					"diagnosticls",
					"dockerls",
					"docker_compose_language_service",
					"elixirls",
					"gopls",
					"grammarly",
					"html",
					"helm_ls",
					"jsonls",
					"ts_ls",
					"jqls",
					"lua_ls",
					"marksman",
					"nginx_language_server",
					"prismals",
					"pylsp",
					"sqlls",
					"taplo",
					"rust_analyzer",
					"tailwindcss",
					"terraformls",
					"tflint",
					"volar",
					"yamlls",
				},

				require("lspconfig").nixd.setup({}),

				require("mason-lspconfig").setup_handlers({
					function(server_name)
						if custom_servers[server_name] then
							custom_servers[server_name]()
						else
							generic_setup(server_name)
						end
					end,
				}),
			})
		end,
	},
	{ "neovim/nvim-lspconfig", event = { "BufReadPre", "BufNewFile", "BufEnter" } },
	{
		-- TERRAFORM DOCS
		"Afourcat/treesitter-terraform-doc.nvim",
		dependencies = { "nvim-treesitter" },
	},
	{
		"luckasRanarison/tailwind-tools.nvim",
		name = "tailwind-tools",
		build = ":UpdateRemotePlugins",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {},
	},
}
