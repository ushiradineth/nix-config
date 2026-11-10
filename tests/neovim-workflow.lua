-- Exercise generated production configuration with disposable files and repositories.
local function eq(actual, expected, label)
	assert(
		vim.deep_equal(actual, expected),
		label .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual)
	)
end
local function wait(label, predicate)
	assert(vim.wait(5000, predicate, 20), label)
end
local function keys(value)
	value = value:gsub("<leader>", vim.g.mapleader)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(value, true, false, true), "xt", false)
end
local function write(path, lines)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	assert(vim.fn.writefile(lines, path) == 0)
end
local function edit(path)
	vim.cmd("edit! " .. vim.fn.fnameescape(path))
end
local function git(args)
	local result = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
	assert(result.code == 0, result.stderr)
	return result.stdout
end
local failures = {}
local function section(name, run)
	local ok, err = pcall(run)
	if ok then
		print("PASS: " .. name)
	else
		failures[#failures + 1] = name .. ": " .. tostring(err)
		print("FAIL: " .. failures[#failures])
		keys("<Esc>")
	end
end
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
vim.fn.chdir(root)
vim.o.lines, vim.o.columns = 40, 120
local copied, copies = nil, 0
vim.g.clipboard = {
	name = "regression capture",
	copy = {
		["+"] = function(lines)
			copied = table.concat(lines, "\n")
			copies = copies + 1
		end,
		["*"] = function()
			error("unexpected primary clipboard write")
		end,
	},
	paste = {
		["+"] = function()
			return { { copied or "" }, "v" }
		end,
		["*"] = function()
			return { { "" }, "v" }
		end,
	},
}
vim.cmd("unlet! g:loaded_clipboard_provider")
vim.cmd("runtime autoload/provider/clipboard.vim")
vim.fn.setreg("a", "sentinel yank")
vim.fn.setreg("0", "sentinel zero")

section("lc clipboard locations, invalid buffers and preservation", function()
	for _, key in ipairs({ "yf", "yp", "yc" }) do
		for _, mode in ipairs({ "n", "x" }) do
			eq(vim.fn.maparg(vim.g.mapleader .. key, mode), "", "removed copy binding " .. key)
		end
	end
	local repo = root .. "/context"
	vim.fn.mkdir(repo .. "/nested", "p")
	vim.fn.chdir(repo)
	git({ "init", "-q" })
	local filename = 'odd "quote` name.ts'
	local path = repo .. "/" .. filename
	local lines = { "abcdef", "ghijkl", "mn~~~op" }
	write(path, lines)
	edit(path)
	vim.bo.filetype = "typescript"
	vim.fn.chdir(repo .. "/nested")
	vim.api.nvim_win_set_cursor(0, { 2, 0 })
	keys("<leader>lc")
	eq(copied, filename .. ":2", "repository relative location")
	eq(vim.api.nvim_buf_get_lines(0, 0, -1, false), lines, "copy preserves buffer")
	eq(vim.fn.getreg("0"), "sentinel zero", "copy preserves yank register")
	eq(vim.fn.getreg("a"), "sentinel yank", "copy preserves named register")
	vim.fn.chdir(root)
	write(root .. "/plain/file.txt", { "fallback ``` fence" })
	edit(root .. "/plain/file.txt")
	keys("<leader>lc")
	eq(copied, "plain/file.txt:1", "cwd fallback")
	local before = copies
	vim.cmd.new()
	keys("<leader>lc")
	vim.api.nvim_buf_set_name(0, root .. "/special")
	vim.bo.buftype = "nofile"
	keys("<leader>lc")
	eq(copies, before, "unnamed and special buffers never copy")
end)

for index, event in ipairs({ "FocusGained", "BufEnter", "CursorHold", "TermClose", "TermLeave" }) do
	section(event .. " reloads clean externally changed files", function()
		local path = root .. "/refresh-" .. event .. ".txt"
		write(path, { "original" })
		edit(path)
		local text = "external " .. string.rep("x", index)
		write(path, { text })
		assert(vim.uv.fs_utime(path, 1700000000 + index, 1700000000 + index))
		vim.api.nvim_exec_autocmds(event, { buffer = 0, group = "CheckExternalChanges" })
		wait(event .. " refresh completes", function()
			return vim.api.nvim_get_current_line() == text
		end)
		eq(vim.api.nvim_get_current_line(), text, event .. " reloads clean buffer")
	end)
end

section("external refresh preserves local changes; ordinary and forced writes remain distinct", function()
	local path = root .. "/modified.txt"
	write(path, { "original" })
	edit(path)
	vim.api.nvim_set_current_line("local unsaved")
	write(path, { "different external contents" })
	assert(vim.uv.fs_utime(path, 1700000100, 1700000100))
	vim.api.nvim_exec_autocmds("FocusGained", { buffer = 0 })
	vim.wait(50)
	eq(vim.api.nvim_get_current_line(), "local unsaved", "modified buffer preserved")
	assert(vim.bo.modified, "local buffer remains modified")
	-- readonly is deterministic even when the builder runs with privileged filesystem access.
	vim.bo.readonly = true
	local ok, err = pcall(vim.cmd.write)
	assert(not ok and tostring(err):find("E45", 1, true), "ordinary write reports readonly error")
	vim.cmd("write!")
	eq(vim.fn.readfile(path), { "local unsaved" }, "explicit force write still works")
	vim.bo.readonly = false
	vim.api.nvim_set_current_line("discard me")
	vim.cmd("edit!")
	eq(vim.api.nvim_get_current_line(), "local unsaved", "explicit force reload still works")
end)

section("real saves select one formatter, honor toggles, and exclude node_modules", function()
	local log = vim.env.FORMATTER_LOG
	local function save(path, expected)
		write(log, {})
		edit(path)
		vim.bo.filetype = "javascript"
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "const value={answer:42}" })
		vim.cmd.write()
		eq(vim.fn.readfile(log), expected, "formatter process count")
		local text = table.concat(vim.fn.readfile(path), "\n")
		if #expected > 0 then
			assert(text:find("const value = ", 1, true), "save writes formatted output")
		else
			eq(text, "const value={answer:42}", "disabled save leaves text alone")
		end
		return text
	end
	local configured = root .. "/biome/main.js"
	local fallback = root .. "/prettier/main.js"
	write(
		root .. "/biome/biome.json",
		{ '{"formatter":{"indentStyle":"space"},"javascript":{"formatter":{"semicolons":"asNeeded"}}}' }
	)
	write(configured, { "" })
	write(fallback, { "" })
	local biome_text = save(configured, { "biome" })
	assert(not biome_text:find(";", 1, true), "Biome project configuration honored")
	local prettier_text = save(fallback, { "prettier" })
	assert(prettier_text:find(";", 1, true), "Prettier fallback actually formats")
	keys("<leader>tf")
	save(fallback, {})
	keys("<leader>tf")
	keys("<leader>tF")
	save(fallback, {})
	-- A buffer-local toggle must not disable formatting in another buffer.
	save(configured, { "biome" })
	edit(fallback)
	keys("<leader>tF")
	save(fallback, { "prettier" })
	local dependency = root .. "/biome/node_modules/dependency/main.js"
	write(dependency, { "" })
	save(dependency, {})
end)

section("Git hunk navigation, range staging and floating review pickers", function()
	for _, suffix in ipairs({ "gd", "gS", "grd", "grD", "grs", "grc", "grh" }) do
		eq(vim.fn.maparg(vim.g.mapleader .. suffix, "n"), "", "retired Git binding " .. suffix)
	end
	local repo = root .. "/git"
	vim.fn.mkdir(repo, "p")
	vim.fn.chdir(repo)
	git({ "init", "-q" })
	git({ "config", "user.name", "Regression Fixture" })
	git({ "config", "user.email", "fixture@example.invalid" })
	git({ "config", "commit.gpgsign", "false" })
	local original = {}
	for index = 1, 80 do
		original[index] = "fixture line " .. index
	end
	write("tracked.txt", original)
	git({ "add", "tracked.txt" })
	git({ "commit", "-qm", "initial fixture" })
	original[80] = "second history entry"
	write("tracked.txt", original)
	git({ "commit", "-qam", "second fixture" })
	local head = git({ "rev-parse", "HEAD" })
	write("untracked.txt", { "untracked fixture", "second line", "third line" })
	edit(repo .. "/tracked.txt")
	local buf = vim.api.nvim_get_current_buf()
	local modified = vim.deepcopy(original)
	modified[4] = "first selected change"
	modified[5] = "adjacent unselected change"
	modified[60] = "distant change"
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, modified)
	vim.cmd.write()
	local gs = require("gitsigns")
	wait("gitsigns attachment", function()
		return #(gs.get_hunks() or {}) == 2
	end)
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	keys("]c")
	wait("next hunk", function()
		return vim.fn.line(".") == 4
	end)
	keys("]c")
	wait("second hunk", function()
		return vim.fn.line(".") == 60
	end)
	keys("[c")
	wait("previous hunk", function()
		return vim.fn.line(".") == 5
	end)
	keys("<leader>gp")
	wait("inline hunk preview", function()
		local ns = vim.api.nvim_get_namespaces().gitsigns_preview_inline
		return ns and #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) > 0
	end)
	vim.api.nvim_win_set_cursor(0, { 4, 0 })
	keys("V<leader>gs")
	wait("selected line staged", function()
		return git({ "diff", "--cached" }):find("first selected change", 1, true) ~= nil
	end)
	local staged = git({ "diff", "--cached" })
	assert(
		not staged:find("adjacent unselected change", 1, true) and not staged:find("distant change", 1, true),
		"range staging excludes other changes"
	)
	vim.api.nvim_win_set_cursor(0, { 60, 0 })
	keys("<leader>gs")
	wait("normal hunk staged", function()
		return git({ "diff", "--cached" }):find("distant change", 1, true) ~= nil
	end)
	assert(not git({ "diff", "--cached" }):find("adjacent unselected change", 1, true))
	git({ "add", "tracked.txt" })
	gs.refresh()
	wait("staged-only file refreshes", function()
		local cache = require("gitsigns.cache").cache[buf]
		return cache
			and cache.hunks
			and #cache.hunks == 0
			and cache.compare_text_head
			and cache.hunks_staged
			and #cache.hunks_staged == 2
	end)
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	keys("]c")
	wait("next staged hunk", function()
		return vim.fn.line(".") == 4
	end)
	keys("2]c")
	wait("counted staged navigation wraps", function()
		return vim.fn.line(".") == 4
	end)
	keys("[c")
	wait("previous staged hunk wraps", function()
		return vim.fn.line(".") == 60
	end)
	edit(repo .. "/untracked.txt")
	wait("untracked file attaches automatically", function()
		return #(gs.get_hunks() or {}) == 1
	end)
	vim.api.nvim_win_set_cursor(0, { 3, 0 })
	keys("]c")
	wait("untracked hunk navigation", function()
		return vim.fn.line(".") == 1
	end)
	vim.api.nvim_set_current_buf(buf)
	keys("<leader>gf")
	local state = require("telescope.actions.state")
	wait("changed files picker opens", function()
		local picker = state.get_current_picker(vim.api.nvim_get_current_buf())
		return picker and picker.manager and picker.manager:num_results() >= 2
	end)
	local picker = state.get_current_picker(vim.api.nvim_get_current_buf())
	local found = false
	for entry in picker.manager:iter() do
		if vim.fs.basename(entry.path or entry.filename or "") == "untracked.txt" then
			found = true
		end
	end
	assert(found, "changed files picker includes untracked files")
	require("telescope.actions").close(picker.prompt_bufnr)
	vim.api.nvim_set_current_buf(buf)
	local tabs, windows = #vim.api.nvim_list_tabpages(), #vim.api.nvim_list_wins()
	local select = vim.ui.select
	local function picker_ready(source)
		local picker
		wait(source .. " ready", function()
			picker = Snacks.picker.get({ source = source })[1]
			return picker and not picker:is_active() and picker.list:count() > 0
		end)
		return picker
	end
	local function closed(picker)
		wait("picker closes", function()
			return picker.closed
		end)
		wait("picker windows cleaned up", function()
			return #vim.api.nvim_list_wins() == windows
		end)
		eq(#vim.api.nvim_list_tabpages(), tabs, "no new tabs")
	end
	for _, case in ipairs({
		{ "gh", "git_log", "input", true },
		{ "gh", "git_log", "preview", false },
	}) do
		vim.api.nvim_set_current_buf(buf)
		keys("<leader>" .. case[1])
		local picker = picker_ready(case[2])
		eq(#vim.api.nvim_list_tabpages(), tabs, "picker opens without tabs")
		assert(vim.api.nvim_win_get_config(picker.input.win.win).relative ~= "", "picker is floating")
		picker:focus(case[3])
		if case[4] then
			vim.cmd.startinsert()
		else
			vim.cmd.stopinsert()
		end
		vim.wait(50)
		keys("<Esc>")
		closed(picker)
	end
	vim.api.nvim_set_current_buf(buf)
	keys("<leader>gh")
	local history = picker_ready("git_log")
	-- Select an older commit: HEAD staying put is meaningful only for a non-HEAD row.
	local first = history:current()
	history.list:move(1)
	assert(history:current() ~= first, "history selects an older commit before Enter")
	history:focus("input")
	keys("<CR>")
	closed(history)
	eq(git({ "rev-parse", "HEAD" }), head, "history Enter does not checkout")
	assert(not git({ "symbolic-ref", "-q", "HEAD" }):match("^$"), "history keeps attached branch")
	eq(vim.ui.select, select, "picker preserves vim.ui.select owner")
end)

assert(#failures == 0, table.concat(failures, "\n"))
print("PASS: all Neovim workflow regressions")
vim.cmd("qa!")
