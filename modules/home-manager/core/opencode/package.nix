{
  pkgs,
  upstream,
}: let
  version = "2.2.5";
  sources = {
    aarch64-darwin = {
      platform = "darwin-arm64";
      hash = "sha512-UwGb2MIJqLSh4wfrkvqNiAohG1Wf5t96Nx7113QvmtCn5LGimmXYN0Tb1chD0mMRRdPvnUguevKRdwM0txZY1Q==";
    };
    x86_64-linux = {
      platform = "linux-x64";
      hash = "sha512-BkHAfTqNsg/qphyHNrnH+DGkOxZsGjamNpM5DvwoEvz7ZAPNw8mEbMXGTCDOAH+/+40Eqeie6KNZBZZQwPCjaA==";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha512-O4qOy/WRYQmhClMB/5qBaoYfzaDK1+PJRQOfU80ixyj5ruQbCxraH+VW2UyHb6RWOlUv41fec+isd62LvCuwuA==";
    };
  };
  source = sources.${pkgs.stdenv.hostPlatform.system};
  # Upgrade OpenCode alone: the locked V2 package predates optional todo support.
  opencode = upstream.overrideAttrs {
    inherit version;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@opencode/cli-${source.platform}/-/cli-${source.platform}-${version}.tgz";
      inherit (source) hash;
    };
    postFixup = pkgs.lib.optionalString pkgs.stdenv.isLinux ''
      formatelf --force-rpath --set-rpath ${pkgs.lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib pkgs.wayland pkgs.libxcb]} $out/bin/.opencode2-wrapped
    '';
  };
in
  pkgs.symlinkJoin {
    name = "opencode-${version}";
    paths = [opencode];
    postBuild = ''
      ln -s ${opencode}/bin/opencode2 "$out/bin/opencode"
    '';
    meta = opencode.meta // {mainProgram = "opencode";};
  }
