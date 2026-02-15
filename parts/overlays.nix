{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;

  overlayFiles =
    builtins.attrNames
    (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name)
      (builtins.readDir ../overlays));

  namedOverlays =
    builtins.listToAttrs
    (map (file: {
        name = lib.removeSuffix ".nix" file;
        value = import (../overlays + "/${file}") inputs;
      })
      overlayFiles);
in {
  flake.overlays =
    namedOverlays
    // {
      default = lib.composeManyExtensions (builtins.attrValues namedOverlays);
    };
}
