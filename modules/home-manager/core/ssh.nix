{myvars, ...}: {
  programs.ssh = {
    enable = true;
    extraOptionOverrides = {
      ForwardAgent = "yes";
      AddKeysToAgent = "yes";
      UseKeychain = "yes";
      IdentityFile = "~/.ssh/${myvars.username}";
    };
  };
}
