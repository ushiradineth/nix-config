return {
	-- SYNTAX HIGHLIGHTING
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"astro",
				"bash",
				"comment",
				"dockerfile",
				"go",
				"hcl",
				"javascript",
				"json",
				"lua",
				"nix",
				"rust",
				"terraform",
				"tsx",
				"typescript",
				"yaml",
				"helm",
			},
			highlight = { enable = true, additional_vim_regex_highlighting = true },
			indent = { enable = true },
			incremental_selection = { enable = true },
			auto_install = true, -- Auto install missing parsers when entering a buffer
			sync_install = true,
		})

		vim.treesitter.language.register("markdown", "mdx")
	end,
}
