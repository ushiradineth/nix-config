{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      material-design-icons
      font-awesome
      nerd-fonts.symbols-only
      nerd-fonts.fira-code

      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      nerd-fonts.zed-mono

      gentium
      cantarell-fonts
      source-code-pro
      twitter-color-emoji
    ];
  };
}
