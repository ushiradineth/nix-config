{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    vim
    spice-vdagent
    mesa-demos
  ];
}
