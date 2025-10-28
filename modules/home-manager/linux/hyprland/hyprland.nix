{
  pkgs,
  myvars,
  ...
}: {
  home.packages = with pkgs; [
    cliphist
    hyprpolkitagent
    hyprland-qtutils # needed for banners and ANR messages
    pavucontrol
    playerctl # Media player control
    wl-clipboard
    libnotify
    brightnessctl
    swww
    xfce.thunar
    grim
    slurp
    swappy
    wf-recorder
    hyprpicker
    bluetuith
  ];

  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd = {
      enable = true;
      enableXdgAutostart = true;
      variables = ["--all"];
    };
    xwayland = {
      enable = true;
    };
    settings = {
      exec-once = [
        "vicinae server" # Start Vicinae server
        "wl-paste --type text --watch cliphist store" # Stores only text data
        "wl-paste --type image --watch cliphist store" # Stores only image data
        "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user start hyprpolkitagent"

        # Dark mode settings
        "gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'"
        "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
        "gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur'"

        "killall -q waybar;sleep .5 && waybar"
        "killall -q swaync;sleep .5 && swaync"

        "swww-daemon"
        "swww img /home/${myvars.username}/wallpaper.jpg"

        "hyprctl setcursor macOS 24"
      ];

      input = {
        numlock_by_default = true;
        repeat_delay = 300;
        follow_mouse = 1;
        float_switch_override_focus = 0;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          scroll_factor = 0.8;
        };
      };

      windowrule = [
        "opacity 1 1, class:^(zen-beta)$" # Full active and unfocused opacity for Zen Browser
      ];

      windowrulev2 = [
        # Zen Browser to workspace 1
        "workspace 1, class:^(zen-beta)$"

        # Ghostty to workspace 2
        "workspace 2, class:^(com.mitchellh.ghostty)$"

        # Figma to workspace 4
        "workspace 4, class:^(figma-linux)$"

        # Bitwarden to workspace 6
        "workspace 6, class:^(Bitwarden)$"
      ];

      gestures = {
        workspace_swipe = 1;
        workspace_swipe_fingers = 3;
        workspace_swipe_distance = 500;
        workspace_swipe_invert = 1;
        workspace_swipe_min_speed_to_force = 30;
        workspace_swipe_cancel_ratio = 0.5;
        workspace_swipe_create_new = 1;
        workspace_swipe_forever = 1;
      };

      general = {
        "$modifier" = "SUPER";
        layout = "dwindle";
        gaps_in = 2;
        gaps_out = 2;
        border_size = 0;
        resize_on_border = true;
      };

      misc = {
        layers_hog_keyboard_focus = true;
        initial_workspace_tracking = 0;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = false;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        enable_swallow = false;
        vfr = false; # Variable Frame Rate
        vrr = 0; # Disable VRR for NVIDIA compatibility

        #  Application not responding (ANR) settings
        enable_anr_dialog = true;
        anr_missed_pings = 20;
      };

      animations = {
        enabled = false;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };

      decoration = {
        rounding = 12;
        blur = {
          enabled = true;
          size = 3;
          passes = 3;
          ignore_opacity = false;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          color = "0x66000000";
          range = 8;
          render_power = 2;
        };
      };

      ecosystem = {
        no_donation_nag = true;
        no_update_news = false;
      };

      cursor = {
        sync_gsettings_theme = false; # Disable to avoid dconf dependency
        no_hardware_cursors = true; # Essential for NVIDIA
        enable_hyprcursor = false;
        warp_on_change_workspace = 2;
        no_warps = true;
      };

      render = {
        explicit_sync = 2; # NVIDIA requires 2 for compatibility
        explicit_sync_kms = 2;
        direct_scanout = false; # Better for NVIDIA screen sharing
      };

      master = {
        new_status = "master";
        new_on_top = 1;
        mfact = 0.5;
      };
    };

    extraConfig = "
      monitor = DP-3, 2560x1440@144, 0x0, 1

      # Environment variables for dark mode
      env = GTK_THEME,WhiteSur-Dark
      env = QT_STYLE_OVERRIDE,adwaita-dark
      env = QT_QPA_PLATFORMTHEME,qt6ct

      # Layer rules
      layerrule = blur, waybar
      layerrule = ignorealpha 0.3, waybar
      layerrule = blurpopups, waybar
      layerrule = blur, swaync-control-center
      layerrule = blur, swaync-notification-window
      layerrule = ignorealpha 0.3, swaync-control-center
      layerrule = ignorealpha 0.3, swaync-notification-window
      layerrule = blur, vicinae
      layerrule = ignorealpha 0, vicinae
      layerrule = noanim, vicinae

      device {
        name = logitech-usb-receiver
        sensitivity = -0.5
    }
    ";
  };
}
