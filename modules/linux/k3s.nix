{myvars, ...}: {
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = ["--disable=traefik" "--cluster-cidr 10.24.0.0/16"];
  };

  # k3s requires a firewall rule to allow access to the Kubernetes API
  networking.firewall.allowedTCPPorts = [6443];

  users.groups.k3s = {};
  users.users."${myvars.username}".extraGroups = ["k3s"];

  # Copy the kubeconfig file to the user's home directory
  systemd.services.sync-kubeconfig = {
    enable = true;
    description = "Copy kubeconfig to user's home directory";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      after = ["k3s.service"];
      ExecStart = ''
        cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && \
        chown ${myvars.username}:${myvars.username} ~/.kube/config
      '';
      Restart = "on-failure";
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/${myvars.username}/.kube 0755 ${myvars.username} ${myvars.username} -"
  ];
}
