{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    pnpm
    pgcli # PostgreSQL CLI
    mycli # MySQL CLI
    k6 # Load testing tool
    vegeta # Load testing tool
    wireshark # Network protocol analyzer
    trivy # Vulnerability scanner
    # TODO: Enable prowler when package is fixed
    # prowler # Cloud security scanner
  ];
}
