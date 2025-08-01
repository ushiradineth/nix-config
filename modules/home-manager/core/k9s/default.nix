{pkgs, ...}: let
  shellAliases = {
    "9" = "k9s";
  };
  k9sSrc = pkgs.fetchFromGitHub {
    owner = "derailed";
    repo = "k9s";
    rev = "v0.32.5"; # This does not affect the K9s version
    sparseCheckout = ["skins"];
    hash = "sha256-fmOB9hE/1J7GfzNNeEAbBo0798FYaUFWnLLHbkxEBb0=";
  };
in {
  home.shellAliases = shellAliases;
  programs.zsh.shellAliases = shellAliases;

  programs.k9s = {
    enable = true;
    aliases = {
      aliases = {
        dp = "deployments";
        s = "services";
        p = "pods";
        cm = "configmaps";
        sec = "v1/secrets";
        ns = "namespaces";
        ds = "daemonsets";
        rs = "replicasets";
        c = "contexts";
        j = "jobs";
        cr = "clusterroles";
        crb = "clusterrolebindings";
        ro = "roles";
        rb = "rolebindings";
        np = "networkpolicies";
        gw = "gateways";
        vs = "virtualservices";
        cert = "certificates";
        cha = "challenges";
      };
    };
    settings = {
      liveViewAutoRefresh = true;
      noExitOnCtrlC = true;
      ui = {
        enableMouse = true;
        headless = false;
        logoless = true;
        crumbsless = false;
        skin = "transparent";
      };
      logger = {
        tail = 200;
        buffer = 500;
        sinceSeconds = 300;
        textWrap = true;
        showTime = true;
      };
    };
    skins = {
      transparent = "${k9sSrc}/skins/transparent.yaml";
    };
  };
}
