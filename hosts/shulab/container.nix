{pkgs, ...}: {
  environment.systemPackages = with pkgs; [docker runc];
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };

  services.k3s.enable = true;
  services.k3s.role = "server";
}
