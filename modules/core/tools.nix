{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    pgcli
    mycli
    k6 # Load testing tool
    vegeta # Load testing tool
    wireshark # Network protocol analyzer
  ];
}
