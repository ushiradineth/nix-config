-- returns true if the character under the cursor is whitespace.
local is_whitespace = function()
	local col = vim.fn.col(".") - 1
	if col <= 0 then
		return true
	end

	local line = vim.fn.getline(".")
	local char_under_cursor = string.sub(line, col, col)

	return string.match(char_under_cursor, "%s") ~= nil
end

-- uses treesitter to determine if cursor is currently hovering over a comment.
local is_comment = function()
	local context = require("cmp.config.context")
	return context.in_treesitter_capture("comment") == true or context.in_syntax_group("Comment")
end

return {
	"hrsh7th/nvim-cmp",
	dependencies = {
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-nvim-lua",
		"hrsh7th/cmp-nvim-lsp-signature-help",
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
			completion = { completeopt = "menu,noinsert,noselect" },
			mapping = cmp.mapping.preset.insert({
				["<Up>"] = cmp.mapping.select_prev_item(),
				["<Down>"] = cmp.mapping.select_next_item(),
				["<Left>"] = cmp.mapping.select_prev_item(),
				["<Right>"] = cmp.mapping.select_next_item(),
				["<C-c>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.close(),
				["<CR>"] = cmp.mapping(function(fallback)
					if cmp.visible() and not is_whitespace() and not is_comment() then
						cmp.confirm({
							behavior = cmp.ConfirmBehavior.Replace,
							select = true,
						})
					else
						fallback()
					end
				end, { "i", "s" }),
			}),
			sources = {
				{ name = "path" },
				{ name = "nvim_lsp" },
				{ name = "nvim_lsp_signature_help" },
				{ name = "nvim_lua", keyword_length = 2 },
				{ name = "buffer", keyword_length = 3 },
				{ name = "luasnip", keyword_length = 2 },
			},
			formatting = {
				format = function(entry, item)
					local abbrev = {
						path = "PATH",
						nvim_lsp = "LSP",
						nvim_lsp_signature_help = "LSP",
						nvim_lua = "LUA",
						buffer = "BUF",
						luasnip = "SNIP",
						calc = "CALC",
						cmdline = "CMD",
					}
					item.menu = "[" .. abbrev[entry.source.name] .. "]"
					return item
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
}
