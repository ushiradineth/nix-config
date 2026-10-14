{pkgs, ...}: {
  home.packages = [(import ../../../lib/semgrep.nix {inherit pkgs;})];

  # Manage the immutable baseline only; private profiles remain user-owned.
  xdg.configFile."semgrep/baseline".source = ../../../security/semgrep;
}
