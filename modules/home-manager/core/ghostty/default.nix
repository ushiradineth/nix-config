{
  config,
  pkgs,
  ...
}: let
  cfg = config.home;
  ghosttyDir = "${cfg.homeDirectory}/.config/ghostty";

  # Platform-specific configuration content
  darwinConfig = ''
    # macOS-specific settings

    # macOS window styling
    macos-non-native-fullscreen = false
    macos-titlebar-style = hidden

    # macOS-specific settings
    macos-option-as-alt = true
    macos-icon = official

    # Override font size for Retina displays
    font-size = 18

    # macOS-specific keybinds (using Cmd as modifier)
    keybind = cmd+p=esc:p

    # Override tmux keybinds with Cmd for macOS
    keybind = cmd+1=text:\x131
    keybind = cmd+2=text:\x132
    keybind = cmd+3=text:\x133
    keybind = cmd+4=text:\x134
    keybind = cmd+5=text:\x135
    keybind = cmd+6=text:\x136
    keybind = cmd+7=text:\x137
    keybind = cmd+8=text:\x138
    keybind = cmd+9=text:\x139

    keybind = cmd+t=text:\x13t
    keybind = cmd+\=text:\x13^
    keybind = cmd+-=text:\x13%
    keybind = cmd+w=text:\x13x
    keybind = cmd+c=text:\x13c
  '';

  linuxConfig = ''
    # Linux-specific settings

    # Window decoration (for Wayland/X11)
    window-decoration = true

    # Linux-specific keybinds (using Ctrl+Shift as modifier)
    keybind = ctrl+shift+p=esc:p

    # Override tmux keybinds with Ctrl+Shift for Linux
    keybind = ctrl+shift+1=text:\x131
    keybind = ctrl+shift+2=text:\x132
    keybind = ctrl+shift+3=text:\x133
    keybind = ctrl+shift+4=text:\x134
    keybind = ctrl+shift+5=text:\x135
    keybind = ctrl+shift+6=text:\x136
    keybind = ctrl+shift+7=text:\x137
    keybind = ctrl+shift+8=text:\x138
    keybind = ctrl+shift+9=text:\x139

    keybind = ctrl+shift+t=text:\x13t
    keybind = ctrl+shift+\=text:\x13^
    keybind = ctrl+shift+-=text:\x13%
    keybind = ctrl+shift+w=text:\x13x
    keybind = ctrl+shift+c=text:\x13c
  '';

  platformConfig =
    if pkgs.stdenv.isDarwin
    then darwinConfig
    else linuxConfig;
in {
  home.file."${ghosttyDir}/config" = {
    text = ''
      # Theme
      # theme = nord

      # Shell integration
      shell-integration = zsh

      # Clipboard
      clipboard-read = allow
      clipboard-write = allow
      copy-on-select = true

      # Window padding
      window-padding-x = 5
      window-padding-y = 5


      # Transparency and blur
      background-opacity = 0.75
      background-blur = true

      # Font
      font-size = 16
      font-style = medium
      font-feature = -liga, +ss03
      font-family = JetBrainsMono Nerd Font Mono

      # Keybinds for tmux integration
      # Using modifier keys that work on both platforms

      # Tmux window switching (Alt+1-9)
      keybind = alt+1=text:\x131
      keybind = alt+2=text:\x132
      keybind = alt+3=text:\x133
      keybind = alt+4=text:\x134
      keybind = alt+5=text:\x135
      keybind = alt+6=text:\x136
      keybind = alt+7=text:\x137
      keybind = alt+8=text:\x138
      keybind = alt+9=text:\x139

      # New tmux window
      keybind = alt+t=text:\x13t

      # Tmux splits
      keybind = alt+\=text:\x13^
      keybind = alt+-=text:\x13%

      # Close pane/window
      keybind = alt+w=text:\x13x
      keybind = alt+c=text:\x13c

      # New line
      keybind = shift+enter=text:\x1b\r

      # Platform-specific configurations
      ${platformConfig}
    '';
  };
}
