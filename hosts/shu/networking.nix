{hostname, ...}: {
  networking.hostName = hostname;
  networking.computerName = hostname; # Darwin Specific
}
