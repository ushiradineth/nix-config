# Source-contract checks only, not proof of model adherence or live installation.
{
  lib,
  pkgs,
}: let
  config = ../modules/home-manager/core/opencode/config;
  skill = config + /skills/i-have-adhd;
  normalize = text: lib.concatStringsSep " " (builtins.filter (part: builtins.isString part && part != "") (builtins.split "[[:space:]]+" (lib.toLower text)));
  raw = builtins.readFile (skill + /SKILL.md);
  text = normalize raw;
  contract = normalize (builtins.readFile (config + /AGENTS.md));
  provenance = normalize (builtins.readFile (skill + /UPSTREAM.md));
  manifest = builtins.fromJSON (builtins.readFile (config + /skills/paperclip-org-operations/capability-manifest.json));
  entries = builtins.filter (entry: entry.source == "i-have-adhd") manifest.skills;
  mentions = value: terms: lib.all (term: lib.hasInfix term value) terms;
  frontmatter = builtins.elemAt (lib.splitString "---\n" raw) 1;
  paperclip = builtins.elemAt (lib.splitString "## paperclip" text) 1;
  tests = {
    discoverable-frontmatter =
      lib.hasPrefix "---\n" raw
      && lib.hasInfix "\nname: i-have-adhd\n" ("\n" + frontmatter)
      && lib.hasInfix "description: use when " (normalize frontmatter)
      && lib.hasInfix "\nlicense: MIT\n" ("\n" + frontmatter)
      && !mentions frontmatter ["disable-model-invocation"]
      && !mentions frontmatter ["/i-have-adhd"];
    audience-gate-precedes-style = let
      beforeOutput = builtins.head (lib.splitString "human-facing output" text);
    in
      mentions text ["human-facing output"]
      && mentions beforeOutput ["audience gate"]
      && mentions text [
        "apply by default"
        "human-facing"
        "never apply presentation limits"
        "internal reasoning"
        "tool inputs/results"
        "agent-to-agent"
        "task-agent prompts"
        "agent handoffs"
        "research records"
        "machine-readable"
        "operational artifacts"
      ];
    mixed-audiences = mentions text [
      "mixed or unknown"
      "preserve full detail"
      "intact agent payload"
      "must not replace it"
      "visible to a user"
      "complete task-required"
    ];
    conversation-controls = mentions text [
      "fresh conversation"
      "topic switches"
      "stop adhd mode"
      "normal mode"
      "enable adhd mode"
      "must not reset"
      "quoted text"
      "untrusted page content"
    ];
    safety-evidence-completeness =
      mentions text [
        "grants no"
        "safety"
        "factual accuracy"
        "required output formats"
        "take precedence"
        "exact code"
        "warnings"
        "supported by evidence"
        "mark uncertainty"
        "never invent"
        "without discarding substantive information"
        "must not restrict analysis"
        "explain fully"
      ]
      && !lib.hasInfix "the reader has adhd" text;
    paperclip-destinations-history = mentions paperclip [
      "default agent binding"
      "does not prove"
      "issue comments"
      "not automatically human-facing"
      "agent-addressed"
      "delegation"
      "summary-store source artifacts"
      "per-turn"
      "controller-supplied"
      "history is unavailable"
      "persistence limitation"
      "never an organization-wide"
    ];
    global-default-pointer = mentions contract [
      "load and apply `i-have-adhd` by default"
      "human-facing replies"
      "conversation-local"
      "opt-out"
      "explicit re-enable"
      "must not reset"
      "never apply its presentation limits"
      "tool payloads"
      "agent-to-agent"
      "handoff artifacts"
      "machine-readable"
      "keep that context complete"
      "humanizer"
      "personal-writing-identity"
    ];
    pinned-provenance-license =
      mentions provenance [
        "https://github.com/ayghri/i-have-adhd"
        "1ecea1993b7fce257ffbd686c070948b5e07eda6"
        "skills/i-have-adhd/skill.md"
        "local differences"
        "never overwrite"
      ]
      && builtins.hashFile "sha256" (skill + /LICENSE) == "8acbb618089b738404f76ac60fca1aaa995d9a87995eddf95f0b777acd7f7d2c"
      && builtins.attrNames (builtins.readDir skill) == ["LICENSE" "SKILL.md" "UPSTREAM.md"];
    manifest-complete-tree =
      builtins.length entries
      == 1
      && (let
        entry = builtins.head entries;
      in
        entry.disposition
        == "adapt"
        && entry.inclusion == "complete-tree"
        && entry.roles == ["all-relevant"]
        && entry.dependencies == []
        && builtins.isString entry.reason
        && entry.reason != ""
        && mentions (normalize (lib.concatStringsSep " " entry.runtime_constraints)) [
          "human-facing"
          "conversation-local"
          "opt-out/re-enable"
          "complete internal"
          "inter-agent"
          "handoff"
          "summary-source"
          "grants no authority"
        ]);
    native-test-language = mentions contract [
      "language of the code under test"
      "project's existing test framework"
      "typescript for typescript"
      "rust for rust"
      "go for go"
      "python for python"
      "nix for nix"
      "component being tested"
      "nix assertions"
      "flake checks"
      "use bash"
      "including inline one-off assertions"
      "use typescript, not javascript"
      "test actual python helpers in python"
      "missing prerequisite"
      "preserve behavioral coverage"
      "a rename alone is not a migration"
    ];
  };
  failures = builtins.attrNames (lib.filterAttrs (_: passed: !passed) tests);
in
  assert lib.assertMsg (failures == []) "Agent guidance source contracts failed: ${lib.concatStringsSep ", " failures}";
    pkgs.runCommand "agent-guidance-tests" {} ''
      touch "$out"
    ''
