{pkgs, ...}: {
  environment.variables = {
    RUSTFLAGS = "-L  ${pkgs.libiconv}/lib";
    CC = "clang";
    CXX = "clang++";
  };
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
    clang
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

    # Package managers
    pnpm
    yarn
    luarocks
  ];
}
