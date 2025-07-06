{...}: {
  programs.nixvim.filetype = {
    extension = {
      md = "markdown";
      mdx = "markdown";
    };
    pattern = {
      ".*/templates/.*%.yaml" = "helm";
    };
  };
}
