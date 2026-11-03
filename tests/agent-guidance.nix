{
  lib,
  pkgs,
}: let
  root = ../modules/home-manager/core/opencode/config;
  config = builtins.fromJSON (builtins.readFile (root + /opencode.json));
  skills = builtins.readDir (root + /skills);
  names = builtins.attrNames skills;
  manifest = builtins.fromJSON (builtins.readFile (root + /skills/paperclip-org-operations/capability-manifest.json));
  selected = map (entry: entry.source) manifest.skills;
  agents = lib.filterAttrs (_: agent: !(agent.disable or false)) config.agent;
  primaries = lib.filterAttrs (_: agent: builtins.elem (agent.mode or "subagent") ["primary" "all"]) agents;
  promptExists = agent:
    if !(agent ? prompt)
    then true
    else let
      match = builtins.match "\\{file:\\./(.*)\\}" agent.prompt;
    in
      match != null && builtins.pathExists (root + "/${builtins.head match}");
  commands = builtins.readDir (root + /commands);
  commandValid = name: let
    content = builtins.readFile (root + "/commands/${name}");
    parts = lib.splitString "---\n" content;
    target =
      if name == "assistant.md"
      then "assistant"
      else "jiyu";
  in
    lib.hasSuffix ".md" name
    && builtins.length parts >= 3
    && lib.hasInfix "\nagent: ${target}\n" ("\n" + builtins.elemAt parts 1);
  identityValid = name: let
    path = root + "/skills/${name}/SKILL.md";
    content = builtins.readFile path;
    parts = lib.splitString "---\n" content;
    frontmatter = builtins.elemAt parts 1;
  in
    lib.hasPrefix "---\n" content
    && lib.hasInfix "\nname: ${name}\n" ("\n" + frontmatter)
    && lib.hasInfix "description:" frontmatter;
  tests = {
    primary-registration = builtins.attrNames primaries == ["assistant" "jiyu"] && config.default_agent == "jiyu";
    leaf-registration = lib.all (name: builtins.hasAttr name agents) ["general" "explore" "reviewer"];
    prompt-references = lib.all promptExists (builtins.attrValues agents);
    command-targets = lib.all commandValid (builtins.attrNames commands);
    discoverable-identities = lib.all identityValid names;
    complete-export = builtins.sort builtins.lessThan selected == names;
    unique-export = builtins.length (lib.unique selected) == builtins.length selected;
    export-dependencies = lib.all (entry: lib.all (name: builtins.elem name selected) entry.dependencies) manifest.skills;
    upstream-attribution = lib.all (name: builtins.pathExists (root + "/skills/${name}/LICENSE")) [
      "jiyu-mode"
      "interrogate"
      "show-me-your-work"
      "loop-on-ci"
      "fix-merge-conflicts"
      "thermo-nuclear-code-quality-review"
    ];
  };
  failures = builtins.attrNames (lib.filterAttrs (_: passed: !passed) tests);
in
  assert lib.assertMsg (failures == []) "Agent harness configuration failed: ${lib.concatStringsSep ", " failures}";
    pkgs.runCommand "agent-guidance-tests" {
      nativeBuildInputs = [pkgs.bash pkgs.coreutils pkgs.diffutils pkgs.shellcheck];
    } ''
      bash -n ${root}/skills/show-me-your-work/scripts/log.sh
      shellcheck ${root}/skills/show-me-your-work/scripts/log.sh
      bash ${./jiyu-log.sh} ${root}/skills/show-me-your-work/scripts/log.sh
      touch "$out"
    ''
