{
  myvars,
  pkgs,
  ...
}: let
  # Username for the user who needs kubeconfig access
  username = "shu";
  kubeconfigPath = "/home/${username}/.kube/config";
in {
  environment.systemPackages = with pkgs; [docker runc];
  virtualisation.docker = {
    enable = true;
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = ["--disable=traefik" "--cluster-cidr 10.24.0.0/16"];
  };

  users.groups = {
    docker = {};
    k3s = {};
  };

  users.users."${myvars.username}" = {
    extraGroups = [
      "docker"
      "k3s"
    ];
  };

  # Copy the kubeconfig file to the user's home directory
  systemd.services.sync-kubeconfig = {
    enable = true;
    description = "Copy kubeconfig to user's home directory";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = ''
        cp /etc/rancher/k3s/k3s.yaml ${kubeconfigPath} && \
        chown ${username}:${username} ${kubeconfigPath}
      '';
      Restart = "on-failure";
    };
    Before = "k3s.service";
  };

  systemd.tmpfiles.rules = [
    "d /home/${username}/.kube 0700 ${username} ${username} -"
  ];
}
