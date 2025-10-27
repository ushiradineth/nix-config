{
  pkgs,
  myvars,
  ...
}: {
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = ["--disable traefik" "--cluster-cidr 10.24.0.0/16"];
  };

  # k3s requires a firewall rule to allow access to the Kubernetes API
  networking.firewall.allowedTCPPorts = [6443];

  users.groups.k3s = {};
  users.users."${myvars.username}".extraGroups = ["k3s"];

  # Create .kube directory
  systemd.tmpfiles.rules = [
    "d /home/${myvars.username}/.kube 0755 ${myvars.username} users -"
  ];

  # Copy the kubeconfig file to the user's home directory
  systemd.services.sync-kubeconfig = {
    enable = true;
    description = "Copy kubeconfig to user's home directory";
    wantedBy = ["multi-user.target"];
    after = ["k3s.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 1; done; cp /etc/rancher/k3s/k3s.yaml /home/${myvars.username}/.kube/config && chown ${myvars.username}:users /home/${myvars.username}/.kube/config && chmod 600 /home/${myvars.username}/.kube/config'";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}

