{
  pkgs,
  myvars,
  config,
  ...
}: {
  users.groups."${myvars.username}" = {};

  # Enable zsh for initial login
  programs.zsh.enable = true;

  # Required for thunar/nautilus/dolphin
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    lshw # lscpu
    parted
  ];

  users.users."${myvars.username}" = {
    description = myvars.userFullname;
    inherit (myvars) initialHashedPassword;
    home = "/home/${myvars.username}";
    group = "${myvars.username}";
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [
      "users"
      "networkmanager"
      "wheel"
      "input"
      "audio"
    ];
  };

  users.users.root = {
    inherit (config.users.users."${myvars.username}") initialHashedPassword;
  };
}
