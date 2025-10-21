{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      material-design-icons
      font-awesome
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      gentium
      cantarell-fonts
      source-code-pro
      twitter-color-emoji

      nerd-fonts.jetbrains-mono
      nerd-fonts.victor-mono
      nerd-fonts.geist-mono
    ];
  };
}
