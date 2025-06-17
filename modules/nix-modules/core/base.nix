{
  pkgs,
  myvars,
  ...
}: {
  nix.package = pkgs.nixVersions.latest;
  environment.variables.EDITOR = "nvim --clean";

  environment.systemPackages = with pkgs; [
    neovim
    git
    tldr # tldr for manual pages
    clang # C/C++ compiler
    gnumake # Makefile
    just # Justfile
    ripgrep # grep alternative
    fastfetch # neofetch alternative
    btop # process monitor

    # Networking tools
    wget # download files
    curlie # curl wrapper with a readable output
    dnsutils # `dig` + `nslookup`
    speedtest-cli # internet bandwidth using speedtest.net
    nmap # Utility for network discovery and security auditing
    tcpdump # command-line packet analyzer
    inetutils # (hostname, ping, telnet, traceroute, whois, ifconfig, etc)
    mtr # functionality of traceroute and ping combined

    # Miscallaneous
    findutils # find, xargs, locate
    which # locate binary
    tree # directory tree
    rsync # file sync
    dust # rust implementation of du
    ncdu_2 # disk usage analyzer
  ];

  programs.zsh = {
    enable = true;
    shellInit = ''
      alias ll="ls -lah"
      alias c="clear"
      alias grep="rg"
      alias neofetch="fastfetch"
      alias curl="curlie"
      alias top="btop"
      alias htop="btop"
      alias n="nvim"
    '';
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = [myvars.username];
  };
}
