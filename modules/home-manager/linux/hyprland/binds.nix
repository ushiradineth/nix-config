{...}: let
in {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Launch applications
      "$modifier,T,exec,ghostty"
      "$modifier,B,exec,zen"
      "$modifier,Y,exec,ghostty -e yazi"
      "$modifier,E,exec,thunar"
      "CTRL,Q,killactive"

      # Move active window
      "$modifier SHIFT,left,movewindow,l"
      "$modifier SHIFT,right,movewindow,r"
      "$modifier SHIFT,up,movewindow,u"
      "$modifier SHIFT,down,movewindow,d"
      "$modifier SHIFT,h,movewindow,l"
      "$modifier SHIFT,l,movewindow,r"
      "$modifier SHIFT,k,movewindow,u"
      "$modifier SHIFT,j,movewindow,d"

      # Switch active window
      "$modifier,left,movefocus,l"
      "$modifier,right,movefocus,r"
      "$modifier,up,movefocus,u"
      "$modifier,down,movefocus,d"
      "$modifier,h,movefocus,l"
      "$modifier,l,movefocus,r"
      "$modifier,k,movefocus,u"
      "$modifier,j,movefocus,d"

      # Workspaces
      "$modifier,1,workspace,1"
      "$modifier,2,workspace,2"
      "$modifier,3,workspace,3"
      "$modifier,4,workspace,4"
      "$modifier,5,workspace,5"
      "$modifier,6,workspace,6"
      "$modifier,7,workspace,7"
      "$modifier,8,workspace,8"
      "$modifier,9,workspace,9"
      "$modifier,0,workspace,10"

      # Move active window to workspace
      "$modifier SHIFT,1,movetoworkspace,1"
      "$modifier SHIFT,2,movetoworkspace,2"
      "$modifier SHIFT,3,movetoworkspace,3"
      "$modifier SHIFT,4,movetoworkspace,4"
      "$modifier SHIFT,5,movetoworkspace,5"
      "$modifier SHIFT,6,movetoworkspace,6"
      "$modifier SHIFT,7,movetoworkspace,7"
      "$modifier SHIFT,8,movetoworkspace,8"
      "$modifier SHIFT,9,movetoworkspace,9"
      "$modifier SHIFT,0,movetoworkspace,10"

      # Ctrl+Tab (since ALT is now CTRL due to key remapping)
      "CTRL,Tab,cyclenext"
      "CTRL,Tab,bringactivetotop"

      # Launchers
      "CTRL,SPACE,exec,vicinae toggle"
      "$modifier,V,exec,vicinae vicinae://extensions/vicinae/clipboard/history"

      # Audio
      ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioPlay, exec, playerctl play-pause"
      ",XF86AudioPause, exec, playerctl play-pause"
      ",XF86AudioNext, exec, playerctl next"
      ",XF86AudioPrev, exec, playerctl previous"
      ",XF86MonBrightnessDown,exec,brightnessctl set 5%-"
      ",XF86MonBrightnessUp,exec,brightnessctl set +5%"

      # Brightness controls
      ",F1,exec,brightnessctl set 5%-"
      ",F2,exec,brightnessctl set +5%"

      # Media controls
      ",F7,exec,playerctl previous"
      ",F8,exec,playerctl play-pause"
      ",F9,exec,playerctl next"

      # Additional media controls (Super + function keys)
      "$modifier,F7,exec,playerctl previous"
      "$modifier,F8,exec,playerctl play-pause"
      "$modifier,F9,exec,playerctl next"

      # Volume controls with regular keys
      "$modifier,F10,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      "$modifier,F11,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      "$modifier,F12,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"

      # Screenshots
      "CTRL SHIFT,5,exec,grim -g \"$(slurp)\" - | swappy -f -"

      # Color picker
      "$modifier,C,exec,hyprpicker -a"

      # Network and Bluetooth management
      "$modifier,W,exec,ghostty -e nmtui"
      "$modifier SHIFT,B,exec,ghostty -e bluetuith"

      # General
      "$modifier,F,fullscreen,"
      "$modifier SHIFT,I,togglesplit," # Toggle between horizontal and vertical split
      "$modifier SHIFT,F,togglefloating," # Float
      "$modifier SHIFT,C,exit," # Closes hyprland
    ];

    bindm = [
      "$modifier, mouse:272, movewindow"
      "$modifier, mouse:273, resizewindow"
    ];
  };
}
