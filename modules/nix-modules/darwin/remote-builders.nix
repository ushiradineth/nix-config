{myvars, ...}: {
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = myvars.hostAddresses.shupi;
        systems = ["aarch64-linux"];
        protocol = "ssh-ng";
        sshUser = "root";
        sshKey = "/Users/${myvars.username}/.ssh/${myvars.username}";
        maxJobs = 1;
      }
      {
        hostName = myvars.hostAddresses.shulab;
        systems = ["x86_64-linux"];
        protocol = "ssh-ng";
        sshUser = "root";
        sshKey = "/Users/${myvars.username}/.ssh/${myvars.username}";
        maxJobs = 1;
      }
      {
        hostName = myvars.hostAddresses.shuos;
        systems = ["x86_64-linux"];
        protocol = "ssh-ng";
        sshUser = "root";
        sshKey = "/Users/${myvars.username}/.ssh/${myvars.username}";
        maxJobs = 4;
      }
    ];
  };
}
