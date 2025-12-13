{
  myvars,
  lib,
  pkgs,
  ...
}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraOptionOverrides = lib.mkMerge [
      {
        ForwardAgent = "yes";
        AddKeysToAgent = "yes";
        IdentityFile = "~/.ssh/${myvars.username}";
      }
      (lib.mkIf pkgs.stdenv.isDarwin {
        UseKeychain = "yes";
      })
    ];
  };
}
