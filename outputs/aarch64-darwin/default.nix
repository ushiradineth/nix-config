{
  lib,
  inputs,
  ...
} @ args: let
  inherit (inputs) haumea;

  data = haumea.lib.load {
    src = ./src;
    inputs = args;
  };
  dataWithoutPaths = builtins.attrValues data;

  outputs = {
    darwinConfigurations = lib.attrsets.mergeAttrsList (map (it: it.darwinConfigurations or {}) dataWithoutPaths);

    colmenaMeta = {
      nodeNixpkgs = lib.attrsets.mergeAttrsList (
        map (it: it.colmenaMeta.nodeNixpkgs or {}) dataWithoutPaths
      );
      nodeSpecialArgs = lib.attrsets.mergeAttrsList (
        map (it: it.colmenaMeta.nodeSpecialArgs or {}) dataWithoutPaths
      );
    };
    colmena = lib.attrsets.mergeAttrsList (map (it: it.colmena or {}) dataWithoutPaths);
  };
in
  outputs
  // {
    inherit data;
  }
