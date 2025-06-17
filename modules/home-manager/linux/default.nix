{
  mylib,
  myvars,
  lib,
  ...
}: {
  home = {
    homeDirectory = "/home/${myvars.username}";

    # Don't show the "Last login" message for every new terminal.
    file.".hushlogin" = {
      text = "";
    };

    file.".gitignore_global" = {
      text = ''
        ~*
        .DS_Store
      '';
    };
  };

  imports =
    (mylib.scanPaths ./.)
    ++ [
      ../core
    ];
}
