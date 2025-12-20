{...}: {
  # Enable keyd service for macOS-style keybinds
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = ["*"];
      settings = {
        main = {
          # Swap Alt and Ctrl so Alt becomes the main modifier (like Cmd on macOS)
          leftalt = "leftcontrol";
          leftcontrol = "leftalt";
          rightalt = "rightcontrol";
          rightcontrol = "rightalt";
        };

        # Special control layer for macOS-like text editing
        # Physical Alt sends Ctrl, so this layer is triggered by physical Alt
        control = {
          a = "C-a";
          backspace = "C-u";
        };

        # Meta/Alt layer for word-level operations
        # Physical Ctrl sends Alt, so this layer is triggered by physical Ctrl
        alt = {
          backspace = "C-w";
        };
      };
    };
  };
}
