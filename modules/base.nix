{
  pkgs,
  myvars,
  ...
}: {
  nix.package = pkgs.nixVersions.latest;
  environment.variables.EDITOR = "nvim --clean";

  environment.systemPackages = with pkgs; [
    # Base
    neovim
    git
    tldr # tldr for manual pages
    clang # C/C++ compiler
    gnumake # Makefile
    just # make alternative (Justfile)
    ripgrep # grep alternative
    fastfetch # neofetch alternative
    lsof # list open files
    btop # process monitor

    # Networking tools
    curlie # curl wrapper with nicer output
    wget # download files
    dnsutils # `dig` + `nslookup`
    socat # replacement of openbsd-netcat
    nmap # a utility for network discovery and security auditing
    speedtest-cli # command-line interface for testing internet bandwidth using speedtest.net
    tcpdump # command-line packet analyzer
    inetutils # inetutils suite of basic networking utilities (hostname, ping, telnet, etc)

    # Miscallaneous
    findutils # find, xargs, locate
    which # locate binary
    tree # directory tree
    rsync # file sync
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
    description = myvars.userFullname;
    shell = pkgs.zsh;
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = [myvars.username];
  };
}
