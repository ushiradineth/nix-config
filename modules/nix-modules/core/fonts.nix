{pkgs, ...}: {
  fonts = {
    fontconfig = {
      enable = true;
      antialias = true;
      defaultFonts = {
        monospace = ["ZedMono Nerd Font"];
        sansSerif = ["JetBrainsMono Nerd Font"];
        serif = ["MesloLGS Nerd Font"];
      };
    };

    packages = with pkgs; [
      material-design-icons
      font-awesome
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
      nerd-fonts.meslo-lg
      nerd-fonts.zed-mono
    ];
  };
}
