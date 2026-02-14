{
  mylib,
  myvars,
  ...
}: {
  home = {
    homeDirectory = "/home/${myvars.username}";

    # Don't show the "Last login" message for every new terminal.
    file.".hushlogin" = {
      text = "";
    };
  };

  imports =
    (mylib.scanPaths ./.)
    ++ [../core];
}
