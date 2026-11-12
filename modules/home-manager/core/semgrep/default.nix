{pkgs, ...}: {
  home.packages = [(import ./package.nix {inherit pkgs;})];

  # Manage the immutable baseline only; private profiles remain user-owned.
  xdg.configFile."semgrep/baseline".source = ./baseline;
}
