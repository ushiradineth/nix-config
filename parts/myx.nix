_: {
  perSystem = {
    lib,
    pkgs,
    system,
    ...
  }: {
    packages = lib.optionalAttrs (system == "aarch64-darwin") {
      myx = pkgs.callPackage ../lib/myx-package.nix {};
    };
    checks = lib.optionalAttrs (system == "aarch64-darwin") {
      myx = import ../tests/myx.nix {inherit lib pkgs;};
      myx-launcher = import ../tests/myx-launcher.nix {inherit lib pkgs;};
    };
  };
}
