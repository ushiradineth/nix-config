{...}: {
  programs.nixvim.filetype = {
    extension = {
      md = "markdown";
      mdx = "markdown";
      tf = "terraform";
      tfvars = "terraform";
      hcl = "terraform";
    };
    pattern = {
      ".*/templates/.*%.yaml" = "helm";
    };
  };
}
