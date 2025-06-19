local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
local home = wezterm.home_dir

-- Sessionizer
local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")
local history = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer-history")
local fd_path = "/etc/profiles/per-user/" .. os.getenv("USER") .. "/bin/fd"
local function starts_with(str, start)
	return str:sub(1, #start) == start
end

local sessionizer_schema = {
	options = {
		always_fuzzy = true,
		callback = history.Wrapper(sessionizer.DefaultCallback), -- tell history that we changed to another workspace
	},

	-- Workspaces
	sessionizer.DefaultWorkspace({}), -- Default workspace ("~")
	history.MostRecentWorkspace({}), -- Most recent workspace

	-- Personal Workspaces
	sessionizer.FdSearch({
		home .. "/Code",
		fd_path = fd_path,
		exclude = {
			"surge",
		},
	}),

	-- Surge Workspaces
	sessionizer.FdSearch({
		home .. "/Code/surge",
		fd_path = fd_path,
	}),

	-- Config Workspaces
	home .. "/nix-config",

	processing = sessionizer.for_each_entry(function(entry)
		-- Replace "Default" with "~"
		if entry.label:match("Default") then
			entry.label = wezterm.format({
				{ Text = "~" },
			})
		end

		-- Replace home with "~"
		entry.label = entry.label:gsub(home, "~")

		-- Group Surge Workspaces
		if starts_with(entry.label, "~/Code/surge") then
			entry.label = wezterm.format({
				{ Text = "Surge: " .. entry.label },
			})
			return
		end

		-- Group Personal Workspaces
		if starts_with(entry.label, "~/Code") then
			entry.label = wezterm.format({
				{ Text = "Personal: " .. entry.label },
			})
			return
		end

		-- Group Config Workspaces
		if entry.label:match("~/nix%-config") then
			entry.label = wezterm.format({
				{ Text = "Config: " .. entry.label },
			})
			return
		end
	end),
}

config.automatically_reload_config = true

-- Colour
config.term = "xterm-256color"
config.color_scheme = "Catppuccin Frappé (Gogh)"

-- Font
config.font = wezterm.font("MesloLGS Nerd Font")
config.font_size = 18.0
config.font_rules = {
	{
		intensity = "Normal",
		font = wezterm.font({
			family = "MesloLGS Nerd Font",
			weight = "Bold",
		}),
	},
}

-- Window
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.window_background_opacity = 0.75
config.window_decorations = "RESIZE"
config.macos_window_background_blur = 100
config.hide_tab_bar_if_only_one_tab = true
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.max_fps = 60
config.animation_fps = 1
config.enable_scroll_bar = false
config.webgpu_power_preference = "LowPower"

config.window_frame = {
	inactive_titlebar_bg = "#353535",
	active_titlebar_bg = "#262838",
	button_fg = "#cccccc",
	button_bg = "#2b2042",
	button_hover_fg = "#ffffff",
	button_hover_bg = "#3b3052",
}

-- Keybinds
config.enable_kitty_keyboard = true
config.enable_csi_u_key_encoding = false
config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{ key = "p", mods = "CMD|SHIFT", action = "Nop" },
	-- Buffer traversal
	{
		-- Skip line left
		key = "LeftArrow",
		mods = "CMD",
		action = act.SendString("\x1bOH"),
	},
	{
		-- Skip line right
		key = "RightArrow",
		mods = "CMD",
		action = act.SendString("\x1bOF"),
	},
	{
		-- Skip word left
		key = "LeftArrow",
		mods = "OPT",
		action = act.SendString("\x1bb"),
	},
	{
		-- Skip word right
		key = "RightArrow",
		mods = "OPT",
		action = act.SendString("\x1bf"),
	},
	{
		-- Delete line
		key = "Backspace",
		mods = "CMD",
		action = act.SendString("\x15"),
	},
	{
		-- Delete word
		key = "Backspace",
		mods = "OPT",
		action = act.SendString("\x1b\x7f"),
	},

	-- mux
	{
		-- Split Horizontal
		key = "|",
		mods = "LEADER",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		-- Split Vertical
		key = "_",
		mods = "LEADER",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		-- Close tab or pane
		key = "x",
		mods = "LEADER",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	{
		-- Close tab or pane
		key = "c",
		mods = "LEADER",
		action = act.CloseCurrentPane({ confirm = true }),
	},

	-- Sessionizer
	{
		key = "s",
		mods = "LEADER",
		action = sessionizer.show(sessionizer_schema),
	},
	{
		key = "f",
		mods = "LEADER",
		action = history.switch_to_most_recent_workspace,
	},
}

return config
