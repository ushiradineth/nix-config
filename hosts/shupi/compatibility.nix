{lib, ...}: {
  disabledModules = [
    "rename.nix"
    "hardware/raspberry-pi/bootloader.nix"
  ];

  imports = [
    (lib.mkAliasOptionModule ["environment" "checkConfigurationOptions"] ["_module" "check"])
  ];
}
