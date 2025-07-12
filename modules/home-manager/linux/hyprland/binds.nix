{...}: let
in {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Launch applications
      "$modifier,T,exec,ghostty"
      "$modifier,B,exec,firefox"
      "$modifier,Y,exec,wezterm -e yazi"
      "ALT,W,killactive"

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

      # Alt+Tab
      "ALT,Tab,cyclenext"
      "ALT,Tab,bringactivetotop"

      # Raycast :<
      "$modifier,SPACE,exec,rofi -show drun"
      "$modifier,V,exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

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
