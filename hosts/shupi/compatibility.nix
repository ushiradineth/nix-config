{lib, ...}: {
  disabledModules = [
    "rename.nix"
    "hardware/raspberry-pi/bootloader.nix"
  ];

  imports = [
    (lib.mkAliasOptionModuleMD ["environment" "checkConfigurationOptions"] ["_module" "check"])
  ];
}
