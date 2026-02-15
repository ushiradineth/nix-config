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
    bell-features = attention,title

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
  '';

  # Linux-specific settings
  linuxConfig = ''
    window-decoration = true
    bell-features = attention,title,system

    # macOS-like clipboard operations
    keybind = ctrl+v=paste_from_clipboard
    keybind = ctrl+c=copy_to_clipboard
    keybind = ctrl+x=copy_to_clipboard
    keybind = ctrl+a=select_all

    # Tmux window switching (Ctrl+1-9) - now that Alt is mapped to Ctrl
    keybind = ctrl+1=text:\x131
    keybind = ctrl+2=text:\x132
    keybind = ctrl+3=text:\x133
    keybind = ctrl+4=text:\x134
    keybind = ctrl+5=text:\x135
    keybind = ctrl+6=text:\x136
    keybind = ctrl+7=text:\x137
    keybind = ctrl+8=text:\x138
    keybind = ctrl+9=text:\x139

    # Allow Ctrl+p to be used by other applications (neovim)
    keybind = ctrl+p=esc:p

    # New tmux tab
    keybind = ctrl+t=text:\x13t

    # Tmux horizontal split
    keybind = ctrl+\=text:\x13^

    # Tmux vertical split
    keybind = ctrl+-=text:\x13%

    # Close tmux window/pane
    keybind = ctrl+w=text:\x13x
  '';

  platformConfig =
    if pkgs.stdenv.isDarwin
    then darwinConfig
    else linuxConfig;
in {
  home.file."${ghosttyDir}/config" = {
    text = ''
      shell-integration = zsh
      gtk-single-instance = true

      clipboard-read = allow
      clipboard-write = allow
      copy-on-select = true
      desktop-notifications = true

      window-padding-x = 5
      window-padding-y = 5

      cursor-color = d6c7df
      cursor-text = 46516c

      background-opacity = 0.75
      background-blur = true

      font-size = 16
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
