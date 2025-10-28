{myvars, ...}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 0;
        hide_cursor = true;
      };
      background = [
        {
          path = "/home/${myvars.username}/wallpaper.jpg";
          blur_passes = 3;
          blur_size = 8;
        }
      ];
      input-field = [
        {
          size = "250, 40";
          position = "0, -100";
          monitor = "";
          dots_center = true;
          dots_spacing = 0.3;
          fade_on_empty = true;
          font_color = "rgba(255, 255, 255, 0.9)";
          inner_color = "rgba(255, 255, 255, 0.1)";
          outer_color = "rgba(255, 255, 255, 0.18)";
          outline_thickness = 2;
          placeholder_text = "<i>Enter Password</i>";
          placeholder_color = "rgba(255, 255, 255, 0.5)";
          shadow_passes = 3;
          shadow_size = 4;
          shadow_color = "rgba(0, 0, 0, 0.3)";
          rounding = 8;
          fail_color = "rgba(214, 61, 61, 0.5)";
          fail_text = "<i>Incorrect</i>";
          fail_transition = 300;
        }
      ];

      label = [
        # Time
        {
          monitor = "";
          text = "$TIME";
          text_align = "center";
          color = "rgba(255, 255, 255, 0.9)";
          font_size = 72;
          font_family = "Geist";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          monitor = "";
          text = "cmd[update:1000] echo $(date +'%A, %B %-d')";
          text_align = "center";
          color = "rgba(255, 255, 255, 0.7)";
          font_size = 24;
          font_family = "Geist";
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
