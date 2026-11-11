{
  pkgs,
  nodeTypes,
}: let
  package = import ../package.nix {inherit pkgs;};
in {
  assistant =
    pkgs.runCommand "opencode-assistant-tests" {
      src = ../.;
      nativeBuildInputs = [pkgs.nodejs_24 pkgs.typescript];
      OPENCODE_ASSISTANT_TEST_BINARY = "${package}/bin/opencode-assistant";
      OPENCODE_ASSISTANT_TEST_MODULES = "${package.connectors}/lib/node_modules";
    } ''
      tsc --project "$src/tests/opencode-assistant.tsconfig.json" --typeRoots ${nodeTypes}
      node --test "$src/tests/opencode-assistant.test.mts" "$src/tests/opencode-affine.test.mts"
      touch "$out"
    '';
  documents = let
    python = pkgs.python3.withPackages (p: [p.pypdf p.pillow p.reportlab]);
  in
    pkgs.runCommand "opencode-document-tests" {
      src = ../.;
      nativeBuildInputs = [python];
      OPENCODE_DOCUMENT_TEST_BINARY = "${package.documentReader}/bin/opencode-document-read";
      OPENCODE_DOCUMENT_TEST_FONT = "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf";
      OPENCODE_PDFTOPPM = "${pkgs.poppler-utils}/bin/pdftoppm";
      OPENCODE_TESSERACT = "${pkgs.tesseract.override {enableLanguages = ["eng"];}}/bin/tesseract";
    } ''
      export PYTHONDONTWRITEBYTECODE=1
      export NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      python3 "$src/tests/opencode-document-test.py"
      touch "$out"
    '';
}
