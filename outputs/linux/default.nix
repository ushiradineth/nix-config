{lib, ...}: let
  mylib = import ../../lib {inherit lib;};
in {
  imports = mylib.scanPaths ./.;
}
