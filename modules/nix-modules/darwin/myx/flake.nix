_: {
  perSystem = {
    lib,
    pkgs,
    system,
    ...
  }: {
    packages = lib.optionalAttrs (system == "aarch64-darwin") {
      myx = pkgs.callPackage ./package.nix {};
    };
    checks = lib.optionalAttrs (system == "aarch64-darwin") {
      myx = import ./tests {inherit lib pkgs;};
      myx-launcher = import ./tests/launcher.nix {inherit lib pkgs;};
    };
  };
}
