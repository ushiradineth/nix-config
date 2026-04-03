{
  pkgs,
  lazytf,
  ...
}: {
  imports = [
    lazytf.homeManagerModules.default
  ];

  programs.lazytf = {
    enable = true;
    package = lazytf.packages.${pkgs.system}.default;
    settings = {
      history.enabled = true;
      mouse = true;
      notification = true;
    };
  };

  home.shellAliases.lt = "lazytf";
  programs.zsh.shellAliases.lt = "lazytf";
}
