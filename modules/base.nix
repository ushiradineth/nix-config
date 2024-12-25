{
  pkgs,
  myvars,
  ...
}: let
  shellAliases = {
    ll = "ls -lah";
    c = "clear";
    grep = "rg";
    neofetch = "fastfetch";
  };
in {
  nix.package = pkgs.nixVersions.latest;
  environment.variables.EDITOR = "nvim --clean";

  environment.systemPackages = with pkgs; [
    neovim
    just
    git
    zsh
    ripgrep
    fastfetch

    # networking tools
    wget
    curl
    mtr # A network diagnostic tool
    iperf3 # Tool to measure IP bandwidth using UDP or TCP
    dnsutils # `dig` + `nslookup`
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    speedtest-cli # Command-line interface for testing internet bandwidth using speedtest.net

    # misc
    file
    findutils
    which
    tree
    rsync
  ];

  home.shellAliases = shellAliases;
  programs.zsh = {
    enable = true;
    shellAliases = shellAliases;
  };

  users.users.${myvars.username} = {
    description = myvars.userfullname;
    shell = pkgs.zsh;
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = [myvars.username];
  };
}
