{pkgs, ...}: {
  programs.zsh.shellInit = ''
    alias lq="lazysql"
    alias lj="lazyjournal"
  '';

  environment.systemPackages = with pkgs; [
    pnpm
    uv # Python package manager
    postgresql # For psql, pg_dump, pg_restore
    mycli # MySQL CLI
    k6 # Load testing tool
    vegeta # Load testing tool
    wireshark # Network protocol analyzer
    trivy # Vulnerability scanner
    # TODO: Enable prowler when package is fixed
    # prowler # Cloud security scanner
    lazyjournal # Easy-to-use journalctl TUI
    lazysql # SQL TUI
    websocat # A command-line client for WebSockets
  ];
}
