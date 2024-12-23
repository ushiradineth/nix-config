{myvars, ...}: {
  home.homeDirectory = "/home/${myvars.username}";
  imports = [
    ../base/core/neovim
    ../base/core/core.nix
    ../base/core/starship.nix
    ../base/core/zsh.nix
    ../base/core/git.nix
    ../base/home.nix
  ];
}
