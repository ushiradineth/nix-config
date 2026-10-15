_: {
  # The shared SSH module applies these authentication restrictions only on Linux.
  services.openssh.extraConfig = ''
    PasswordAuthentication no
    KbdInteractiveAuthentication no
  '';
}
