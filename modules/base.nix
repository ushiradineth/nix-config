{
  pkgs,
  myvars,
  ...
}: {
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

  programs.zsh = {
    enable = true;
    shellInit = ''
      alias ll="ls -lah"
      alias c="clear"
      alias grep="rg"
      alias neofetch="fastfetch"
    '';
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
