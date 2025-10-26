{
  pkgs,
  lib,
  ...
}: {
  boot.loader.systemd-boot.enable = lib.mkForce false; # due to lanzaboote
  boot.loader.efi.canTouchEfiVariables = true;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  environment.systemPackages = with pkgs; [
    sbctl
  ];
}
