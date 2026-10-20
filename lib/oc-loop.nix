{
  pkgs,
  opencode,
}: let
  source = pkgs.lib.fileset.toSource {
    root = ../scripts;
    fileset = pkgs.lib.fileset.unions [../scripts/oc-loop.mjs ../scripts/oc-loop-autonomy.mjs];
  };
in
  pkgs.writeShellApplication {
    name = "oc-loop";
    runtimeInputs = [pkgs.nodejs opencode];
    text = ''
      export OC_LOOP_OPENCODE="''${OC_LOOP_OPENCODE:-${opencode}/bin/opencode}"
      exec ${pkgs.nodejs}/bin/node ${source}/oc-loop.mjs "$@"
    '';
  }
