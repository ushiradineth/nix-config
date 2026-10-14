{pkgs}: let
  python = pkgs.python3.withPackages (p: [p.pyyaml]);
in
  pkgs.writeShellApplication {
    name = "semgrep-local";
    runtimeInputs = [python pkgs.semgrep pkgs.git] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.bubblewrap];
    text = ''
      export SEMGREP_LOCAL_BASELINE=${../security/semgrep}
      export SEMGREP_LOCAL_ENGINE=${pkgs.semgrep}/bin/semgrep
      export SEMGREP_LOCAL_CA=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export SEMGREP_LOCAL_PATH=${pkgs.lib.makeBinPath [python pkgs.semgrep pkgs.git]}
      ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''export SEMGREP_LOCAL_BWRAP=${pkgs.bubblewrap}/bin/bwrap''}
      exec ${python}/bin/python3 -I -B ${../scripts/semgrep-scan.py} "$@"
    '';
  }
