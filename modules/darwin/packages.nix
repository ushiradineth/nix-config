{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Utilities
    curl
    fastfetch
    ripgrep
    speedtest-cli
    pgcli
    tokei
    tldr
    gnumake
    just
    sshpass

    # Programming Languages & Tools
    lua5_1
    python3
    ansible
    go
    gcc
    jdk17
    maven
    nodejs_22
    rustup
    eslint_d
    nixd

    # Version managers
    nodenv
    pyenv

    # Package managers
    pnpm
    yarn
    luarocks
  ];
}
