{
  pkgs,
  nodeTypes,
}: let
  quotaModule = import ../. {
    inherit pkgs;
    myvars = import ../../../../../vars {};
    config.xdg.cacheHome = "/unused-quota-test-cache";
    config.home.homeDirectory = "/unused-navigation-test-home";
    config.home.sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
    };
  };
  quotaHelper = builtins.head quotaModule.home.packages;
in {
  navigation =
    pkgs.runCommand "tmux-navigation-tests" {
      src = ../.;
      nativeBuildInputs = [pkgs.nodejs pkgs.tmux pkgs.fzf pkgs.typescript];
      TMUX_NAVIGATION_TEST_SHELL = pkgs.runtimeShell;
    } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      tsc --project "$src/tests/tmux-navigation.tsconfig.json" --typeRoots ${nodeTypes}
      node --test "$src/tests/tmux-navigation.test.mts"
      touch "$out"
    '';
  quota =
    pkgs.runCommand "codex-quota-tests" {
      src = ../.;
      nativeBuildInputs = [pkgs.nodejs pkgs.tmux pkgs.typescript];
      CODEX_QUOTA_TEST_HELPER = "${quotaHelper}/bin/codex-quota";
      CODEX_QUOTA_TEST_CONFIG = pkgs.writeText "quota-tmux.conf" quotaModule.programs.tmux.extraConfig;
    } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      tsc --project "$src/tests/codex-quota.tsconfig.json" --typeRoots ${nodeTypes}
      node --test "$src/tests/codex-quota.test.mts"
      touch "$out"
    '';
}
