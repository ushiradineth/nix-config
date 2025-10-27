{...}: {
  # Enable keyd service for macOS-style keybinds
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = ["*"];
      settings = {
        main = {
          # Swap Ctrl and Alt for macOS-style shortcuts
          leftalt = "leftcontrol";
          leftcontrol = "leftalt";
          rightalt = "rightcontrol";
          rightcontrol = "rightalt";
        };
      };
    };
  };
}
