{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Utilities
    pgcli # postgres cli
    tokei # code statistics

    # Programming Languages & Tools
    lua5_1
    python3
    ansible
    sshpass # ssh password manager (needed for ansible)
    go
    gcc
    jdk17
    maven
    nodejs_22
    rustup
    libiconv
    eslint_d
    nixd

    # Version managers
    nodenv
    pyenv
    tenv

    # Package managers
    pnpm
    yarn
    luarocks
  ];
}
