inputs: _final: prev: let
  inherit (inputs.nixpkgs) lib;

  brokenPackages = [
    # Add darwin-incompatible packages here.
  ];
in
  if prev.stdenv.isDarwin
  then
    lib.genAttrs brokenPackages (
      pname: lib.warn "${pname} is disabled on Darwin" prev.emptyDirectory
    )
  else {}
