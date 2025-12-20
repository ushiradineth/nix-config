{...}: let
in {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Launch applications
      "$modifier,T,exec,ghostty +new-window"
      "$modifier,B,exec,zen-beta -P default"
      "$modifier,E,exec,nautilus"
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

      "CTRL,Tab,cyclenext,"
      "CTRL SHIFT,Tab,cyclenext,prev"

      # Launchers
      "CTRL,SPACE,exec,vicinae toggle"
      "$modifier,V,exec,vicinae vicinae://extensions/vicinae/clipboard/history"

      # Audio (with SwayOSD visual feedback)
      ",XF86AudioRaiseVolume,exec,swayosd-client --output-volume raise"
      ",XF86AudioLowerVolume,exec,swayosd-client --output-volume lower"
      ",XF86AudioMute,exec,swayosd-client --output-volume mute-toggle"
      ",XF86AudioPlay,exec,playerctl play-pause"
      ",XF86AudioPause,exec,playerctl play-pause"
      ",XF86AudioNext,exec,playerctl next"
      ",XF86AudioPrev,exec,playerctl previous"
      ",XF86MonBrightnessDown,exec,swayosd-client --brightness lower"
      ",XF86MonBrightnessUp,exec,swayosd-client --brightness raise"

      # Brightness controls
      ",F1,exec,swayosd-client --brightness lower"
      ",F2,exec,swayosd-client --brightness raise"

      # Media controls
      ",F7,exec,playerctl previous"
      ",F8,exec,playerctl play-pause"
      ",F9,exec,playerctl next"

      # Additional media controls (Super + function keys)
      "$modifier,F7,exec,playerctl previous"
      "$modifier,F8,exec,playerctl play-pause"
      "$modifier,F9,exec,playerctl next"

      # Volume controls with regular keys (with SwayOSD visual feedback)
      "$modifier,F10,exec,swayosd-client --output-volume mute-toggle"
      "$modifier,F11,exec,swayosd-client --output-volume lower"
      "$modifier,F12,exec,swayosd-client --output-volume raise"

      # Screenshots
      "CTRL SHIFT,5,exec,grim -g \"$(slurp)\" - | swappy -f -"

      # Color picker
      "$modifier,C,exec,hyprpicker -a"

      # Network, Bluetooth, and Audio management
      "$modifier,W,exec,ghostty -e nmtui"
      "$modifier SHIFT,B,exec,ghostty -e bluetuith"
      "$modifier,A,exec,pavucontrol"

      # General
      "$modifier,F,fullscreen,"
      "CTRL,slash,layoutmsg,orientationcycle left top" # Toggle layout orientation
      "CTRL,comma,layoutmsg,togglesplit" # Toggle accordion-like split
      "$modifier SHIFT,F,togglefloating," # Toggle floating
      "$modifier SHIFT,C,exit,"
    ];

    bindm = [
      "$modifier, mouse:272, movewindow"
      "$modifier, mouse:273, resizewindow"
    ];
  };
}
