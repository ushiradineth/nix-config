{
  pkgs,
  agenix,
  myvars,
  mylib,
  ...
}: {
  imports = [
    agenix.darwinModules.default
  ];

  # macOS launchd service logging
  launchd.daemons."activate-agenix".serviceConfig = {
    StandardErrorPath = "/Library/Logs/org.nixos.activate-agenix.stderr.log";
    StandardOutPath = "/Library/Logs/org.nixos.activate-agenix.stdout.log";
  };

  environment.systemPackages = [
    agenix.packages.${pkgs.system}.default
    pkgs.age
  ];
}
