_inputs: final: prev:
if prev.stdenv.hostPlatform.system == "aarch64-darwin"
then {myx = final.callPackage ../lib/myx-package.nix {};}
else {}
