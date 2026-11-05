{pkgs}: let
  nodejs = pkgs.nodejs_24;
  assistantScripts = pkgs.lib.fileset.toSource {
    root = ../scripts;
    fileset = pkgs.lib.fileset.unions [
      ../scripts/opencode-assistant.mts
      ../scripts/opencode-affine.mts
      ../scripts/opencode-documents.mts
    ];
  };
  documentPython = pkgs.python3.withPackages (p: [p.pypdf]);
  documentOcr = pkgs.tesseract.override {enableLanguages = ["eng"];};
  documentReader = pkgs.writeShellApplication {
    name = "opencode-document-read";
    text = ''
      export OPENCODE_PDFTOPPM=${pkgs.poppler-utils}/bin/pdftoppm
      export OPENCODE_TESSERACT=${documentOcr}/bin/tesseract
      exec ${documentPython}/bin/python3 -I ${../scripts/opencode-document.py}
    '';
  };
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
      export OPENCODE_DOCUMENT_READER=${documentReader}/bin/opencode-document-read
      exec ${nodejs}/bin/node ${assistantScripts}/opencode-assistant.mts "$@"
    '';
    passthru = {inherit connectors documentReader;};
  }
