{
  config,
  lib,
  pkgs,
  ...
}: let
  docker = "${config.virtualisation.docker.package}/bin/docker";
  patchSource = ../../../containers/affine/import-errors.ts;
  dockerfile = ../../../containers/affine/Dockerfile;
  revision = builtins.substring 0 16 (builtins.hashString "sha256" (builtins.readFile patchSource + builtins.readFile dockerfile));
  image = "affine-local:0.27.4-import-errors-${revision}";
  context = pkgs.runCommand "affine-web-build-context" {} ''
    mkdir "$out"
    cp ${dockerfile} "$out/Dockerfile"
    cp ${patchSource} "$out/import-errors.ts"
  '';
in {
  virtualisation.oci-containers.containers.affine.image = lib.mkForce image;

  systemd.services.affine-web-image = {
    description = "Build the pinned AFFiNE web Snapshot error fix";
    after = ["docker.service"];
    requires = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "10min";
    };
    script = ''
      ${docker} build --tag ${image} ${context}
    '';
  };
  systemd.services.docker-affine = {
    after = ["affine-web-image.service"];
    requires = ["affine-web-image.service"];
  };
}
