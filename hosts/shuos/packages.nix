{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    firefox
    sbctl # for secure boot
  ];
}
