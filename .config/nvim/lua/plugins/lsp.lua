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
		require("lspconfig").lua_ls.setup({
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
					"eslint-lsp",
					"gopls",
					"grammarly",
					"html",
					"helm_ls",
					"jsonls",
					"tsserver",
					"jqls",
					"lua_ls",
					"marksman",
					"nginx_language_server",
					"spectral",
					"intelephense",
					"prismals",
					"pylsp",
					"sqlls",
					"taplo",
					"tailwindcss",
					"terraformls",
					"tflint",
					"volar",
					"yamlls",
				},

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
	{
		"neovim/nvim-lspconfig",
	},
	{
		-- TERRAFORM DOCS
		"Afourcat/treesitter-terraform-doc.nvim",
		dependencies = { "nvim-treesitter" },
	},
}
