local wezterm = require("wezterm")
local sessionizer = require("sessionizer")
local config = wezterm.config_builder()
local act = wezterm.action

config.automatically_reload_config = true

-- Colour
config.term = "xterm-256color"
config.color_scheme = "Catppuccin Macchiato (Gogh)"

-- Font
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 18.0
config.font_rules = {
	{
		intensity = "Normal",
		font = wezterm.font({
			family = "MesloLGS Nerd Font Mono",
			weight = "Bold",
		}),
	},
}

-- Window
config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 10,
}
config.window_background_opacity = 0.85
config.window_decorations = "RESIZE"
config.macos_window_background_blur = 100
config.hide_tab_bar_if_only_one_tab = true
config.enable_tab_bar = true
config.use_fancy_tab_bar = true

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
		key = "f",
		mods = "LEADER",
		action = wezterm.action_callback(sessionizer.toggle),
	},
	{
		key = "F",
		mods = "LEADER",
		action = wezterm.action_callback(sessionizer.resetCacheAndToggle),
	},
}

return config
