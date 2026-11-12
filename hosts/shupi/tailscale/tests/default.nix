{pkgs}:
pkgs.runCommand "tailnet-policy-tests" {
  src = ../.;
  nativeBuildInputs = [pkgs.nodejs pkgs.bash pkgs.jq pkgs.coreutils pkgs.diffutils pkgs.shellcheck];
} ''
  cd "$src"
  bash -n tailnet-policy.sh
  shellcheck tailnet-policy.sh
  node --test tests/tailnet-policy.test.mts
  touch "$out"
''
