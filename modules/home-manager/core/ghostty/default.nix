{
  config,
  pkgs,
  ...
}: let
  cfg = config.home;
  ghosttyDir = "${cfg.homeDirectory}/.config/ghostty";

  # macOS-specific settings
  darwinConfig = ''
    # macOS window styling
    macos-non-native-fullscreen = false
    macos-titlebar-style = hidden

    # macOS-specific settings
    macos-option-as-alt = true
    macos-icon = official

    # Override tmux keybinds with Cmd for macOS
    keybind = cmd+Digit1=text:\x131
    keybind = cmd+Digit2=text:\x132
    keybind = cmd+Digit3=text:\x133
    keybind = cmd+Digit4=text:\x134
    keybind = cmd+Digit5=text:\x135
    keybind = cmd+Digit6=text:\x136
    keybind = cmd+Digit7=text:\x137
    keybind = cmd+Digit8=text:\x138
    keybind = cmd+Digit9=text:\x139

    # Allow Alt+p to be used by other applications (neovim)
    keybind = cmd+p=esc:p

    # New tmux tab
    keybind = cmd+t=text:\x13t

    # Tmux horizontal split
    keybind = cmd+\=text:\x13^

    # Tmux vertical split
    keybind = cmd+-=text:\x13%

    # Close tmux window/pane
    keybind = cmd+w=text:\x13x
    keybind = cmd+c=text:\x13c
  '';

  # Linux-specific settings
  linuxConfig = ''
    window-decoration = true

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

    # Allow Alt+p to be used by other applications (neovim)
    keybind = alt+p=esc:p

    # New tmux tab
    keybind = alt+t=text:\x13t

    # Tmux horizontal split
    keybind = alt+\=text:\x13^

    # Tmux vertical split
    keybind = alt+-=text:\x13%

    # Close tmux window/pane
    keybind = alt+w=text:\x13x
    keybind = alt+c=text:\x13c
  '';

  platformConfig =
    if pkgs.stdenv.isDarwin
    then darwinConfig
    else linuxConfig;
in {
  home.file."${ghosttyDir}/config" = {
    text = ''
      shell-integration = zsh

      clipboard-read = allow
      clipboard-write = allow
      copy-on-select = true

      window-padding-x = 5
      window-padding-y = 5

      background-opacity = 0.75
      background-blur = true

      font-size = 18
      font-style = medium
      font-feature = -calt, +ccmp
      font-family = JetBrainsMono Nerd Font Mono

      # New line
      keybind = shift+enter=text:\x1b\r

      # Platform-specific configurations
      ${platformConfig}
    '';
  };
}
