{pkgs}: let
  nodejs = pkgs.nodejs_24;
  connectors = (pkgs.buildNpmPackage.override {inherit nodejs;}) {
    pname = "opencode-assistant-connectors";
    version = "1.0.0";
    src = ./opencode-assistant;
    npmDeps = pkgs.importNpmLock {npmRoot = ./opencode-assistant;};
    npmConfigHook = pkgs.importNpmLock.npmConfigHook;
    npmFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      cp -r node_modules "$out/lib/"
      runHook postInstall
    '';
  };
in
  pkgs.writeShellApplication {
    name = "opencode-assistant";
    runtimeInputs = [nodejs];
    text = ''
      export OPENCODE_ASSISTANT_MODULES=${connectors}/lib/node_modules
      exec ${nodejs}/bin/node ${../scripts/opencode-assistant.mts} "$@"
    '';
    passthru = {inherit connectors;};
  }
