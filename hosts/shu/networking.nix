let
  hostname = "shu";
in {
  networking.hostName = hostname;
  networking.computerName = hostname; # Darwin Specific
}
