_inputs: final: prev:
if prev.stdenv.hostPlatform.system == "aarch64-darwin"
then {myx = final.callPackage ./package.nix {};}
else {}
