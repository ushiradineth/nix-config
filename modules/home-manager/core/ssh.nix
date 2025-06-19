{
  myvars,
  lib,
  pkgs,
  ...
}: {
  programs.ssh = {
    enable = true;
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
