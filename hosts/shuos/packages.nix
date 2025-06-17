{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    kitty
    firefox
  ];
}
