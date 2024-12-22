let
  hostname = "shu";
in {
  networking.hostName = hostname;

  # Darwin Specific
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;
}
