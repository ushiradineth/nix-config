{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    pgcli # PostgreSQL CLI
    mycli # MySQL CLI
    k6 # Load testing tool
    vegeta # Load testing tool
    wireshark # Network protocol analyzer
    trivy # Vulnerability scanner
    prowler # Cloud security scanner
  ];
}
