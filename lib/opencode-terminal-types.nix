{pkgs}: let
  nodeTypes = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@types/node/-/node-24.0.15.tgz";
    hash = "sha512-oaeTSbCef7U/z7rDeJA138xpG3NuKc64/rZ2qmUFkFJmnMsAPaluIifqyWd8hSSMxyP9oie3dLAqYPblag9KgA==";
  };
  undiciTypes = pkgs.fetchurl {
    url = "https://registry.npmjs.org/undici-types/-/undici-types-7.8.0.tgz";
    hash = "sha512-9UJ2xGDvQ43tYyVMpuHlsgApydB8ZKfVYTsLDhXkFL/6gfkp+U8xTGdh8pMJv1SpZna0zxG1DwsKZsreLbXBxw==";
  };
in
  pkgs.runCommand "opencode-terminal-type-definitions" {
    nativeBuildInputs = [pkgs.gnutar];
  } ''
    mkdir -p "$out/node" "$out/undici-types"
    tar -xzf ${nodeTypes} --strip-components=1 -C "$out/node"
    tar -xzf ${undiciTypes} --strip-components=1 -C "$out/undici-types"
  ''
