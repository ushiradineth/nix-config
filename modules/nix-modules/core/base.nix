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
    just # Justfile
    tldr # tldr for manual pages
    clang # C/C++ compiler
    gnumake # Makefile
    ripgrep # grep alternative
    fastfetch # neofetch alternative
    btop # process monitor
    colmena # remote deployment via SSH
    expect # Automate interactive applications

    # Networking tools
    wget # download files
    curlie # curl wrapper with a readable output
    dnsutils # `dig` + `nslookup`
    speedtest-cli # internet bandwidth using speedtest.net
    nmap # Utility for network discovery and security auditing
    tcpdump # command-line packet analyzer
    inetutils # (hostname, ping, telnet, traceroute, whois, ifconfig, etc)
    mtr # functionality of traceroute and ping combined

    # Miscellaneous
    findutils # find, xargs, locate
    which # locate binary
    tree # directory tree
    rsync # file sync
    dust # rust implementation of du
    ncdu # disk usage analyzer
    jq # json parser
    procs # Modern process viewer
    killall
    pciutils # lspci
    usbutils # lsusb
  ];

  programs.zsh = {
    enable = true;
    shellInit = ''
      alias ll="ls -lah"
      alias c="clear"
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

    # Enable binary cache fallback
    fallback = true;

    # Increase connection timeout for better cache reliability
    connect-timeout = 5;

    substituters = [
      "https://cache.nixos.org"
      "https://vicinae.cachix.org"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];

    builders-use-substitutes = true;
  };
}
