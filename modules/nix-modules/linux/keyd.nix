{...}: {
  # Enable keyd service for macOS-style keybinds
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = ["*"];
      settings = {
        main = {
          # Swap left Alt and Ctrl
          leftalt = "leftcontrol";
          leftcontrol = "leftalt";

          # Swap right Alt and Ctrl
          rightalt = "rightcontrol";
          rightcontrol = "rightalt";
        };

        # Override to keep Ctrl+C working for interrupt
        # This makes both physical Alt+C and physical Ctrl+C send Ctrl+C
        "alt" = {
          c = "C-c";
        };
      };
    };
  };
}
