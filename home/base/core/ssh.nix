{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        ForwardAgent yes
        AddKeysToAgent yes
        IdentityFile ~/.ssh/shu
    '';
  };
}
