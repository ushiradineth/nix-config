local is_whitespace = function()
	-- returns true if the character under the cursor is whitespace.
	local col = vim.fn.col(".") - 1
	local line = vim.fn.getline(".")
	local char_under_cursor = string.sub(line, col, col)

	if col == 0 or string.match(char_under_cursor, "%s") then
		return true
	else
		return false
	end
end

local is_comment = function()
	-- uses treesitter to determine if cursor is currently in a comment.
	local context = require("cmp.config.context")
	return context.in_treesitter_capture("comment") == true or context.in_syntax_group("Comment")
end

return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local cmp = require("cmp")
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				window = {},
				experimental = {
					ghost_text = false,
				},
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				enabled = function()
					if is_comment() or is_whitespace() then
						return false
					else
						return true
					end
				end,
				completion = { completeopt = "menu,menuone,noinsert,noselect" },
				mapping = cmp.mapping.preset.insert({
					["<Up>"] = cmp.mapping.select_prev_item(),
					["<Down>"] = cmp.mapping.select_next_item(),
					["<Left>"] = cmp.mapping.select_prev_item(),
					["<Right>"] = cmp.mapping.select_next_item(),
					["<C-c>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.close(),
					["<CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}),
				}),
				sources = {
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
					-- { name = "cmdline" },
					-- { name = "buffer", keyword_length = 3 },
				},
				formatting = {
					format = function(entry, vim_item)
						local abbrev = {
							nvim_lsp = "LSP",
							luasnip = "SNIP",
							path = "PATH",
							-- cmdline = "CMD",
							-- buffer = "BUF",
						}
						vim_item.menu = "[" .. abbrev[entry.source.name] .. "]"
						return vim_item
					end,
				},
			})
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline({}),
				completion = { autocomplete = false },
				sources = {
					{ name = "cmdline" },
				},
			})
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				completion = { autocomplete = false },
				sources = {
					{ name = "buffer" },
				},
			})
		end,
	},
}
