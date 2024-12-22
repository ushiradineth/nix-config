local function set_cmdheight()
	if vim.fn.mode() == "c" then
		vim.opt.cmdheight = 1 -- Show the command line in command mode
	else
		vim.opt.cmdheight = 0 -- Hide the command line in other modes
	end
end

-- Autocommands for entering and leaving command mode
vim.api.nvim_create_autocmd("CmdlineEnter", {
	pattern = "*",
	callback = function()
		vim.defer_fn(function()
			set_cmdheight()
		end, 0)
	end,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
	pattern = "*",
	callback = function()
		vim.defer_fn(function()
			set_cmdheight()
		end, 0)
	end,
})

-- Initial setup of cmdheight
set_cmdheight()

-- Fix comment string for terraform
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("FixTerraformCommentString", { clear = true }),
	callback = function(ev)
		vim.bo[ev.buf].commentstring = "# %s"
	end,
	pattern = { "terraform", "hcl" },
})
