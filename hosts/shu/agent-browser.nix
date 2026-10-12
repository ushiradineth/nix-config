{pkgs, ...}: let
  helper = ../../modules/home-manager/core/opencode/config/skills/browser-workflow/scripts/browser_task.py;
in {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "agent-browser-task" ''
      exec ${pkgs.python3}/bin/python3 -I ${helper} --installed "$@"
    '')
  ];
}
