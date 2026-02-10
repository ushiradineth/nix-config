_: {
  programs.nixvim.plugins.lsp = {
    enable = true;
    servers = {
      eslint = {
        enable = true;
        settings = {
          workingDirectory.mode = "location";
        };
      };

      yamlls = {
        enable = true;
        settings = {
          yaml = {
            schemaStore = {
              enable = true;
              url = "https://www.schemastore.org/api/json/catalog.json";
            };
            schemas = {
              "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/all.json" = "*.{yml,yaml}";
              "http://json.schemastore.org/ansible-stable-2.9" = "roles/tasks/**/*.{yml,yaml}";
              "http://json.schemastore.org/github-workflow" = ".github/workflows/*";
              "http://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
              "http://json.schemastore.org/prettierrc" = ".prettierrc.{yml,yaml}";
              "http://json.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
              "http://json.schemastore.org/ansible-playbook" = "*play*.{yml,yaml}";
              "http://json.schemastore.org/chart" = "Chart.{yml,yaml}";
              "https://json.schemastore.org/dependabot-v2" = ".github/dependabot.{yml,yaml}";
              "https://json.schemastore.org/gitlab-ci" = "*gitlab-ci*.{yml,yaml}";
              "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json" = "*api*.{yml,yaml}";
              "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = "*docker-compose*.{yml,yaml}";
              "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" = "*flow*.{yml,yaml}";
              "https://api.bitbucket.org/schemas/pipelines-configuration" = "*bitbucket-pipelines*.{yml,yaml}";
              "values.schema.json" = "values.yaml";
            };
            format.enabled = true;
            validate = true;
            completion = true;
            hover = true;
          };
        };
      };

      rust_analyzer = {
        enable = true;
        installRustc = true;
        installCargo = true;
      };

      clangd.enable = true;

      gopls.enable = true; # Go LSP
      lua_ls.enable = true;
      bashls.enable = true;
      pylsp.enable = true;
      nixd.enable = true;
      marksman.enable = true; # Markdown LSP
      elixirls.enable = true;

      astro.enable = true;
      ts_ls.enable = true;
      volar.enable = true;
      tailwindcss.enable = true; # Tailwind LSP
      html.enable = true; # HTML LSP
      cssls.enable = true;

      jqls.enable = true;
      jsonls.enable = true;
      taplo.enable = true; # TOML LSP

      terraformls.enable = true;
      tflint.enable = true;
      dockerls.enable = true;
      helm_ls.enable = true;
      nginx_language_server.enable = true;

      diagnosticls.enable = true; # Diagnostics engine
      typos_lsp.enable = true;
    };
  };

  programs.nixvim.keymaps = [
    {
      key = "K";
      mode = ["n"];
      action = ":lua vim.lsp.buf.hover()<CR>";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<leader>cd";
      mode = ["n"];
      action = ":lua vim.lsp.buf.definition()<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Go to Definition";
      };
    }
    {
      key = "<leader>cR";
      mode = ["n" "v"];
      action = ":lua vim.lsp.buf.references()<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Find References";
      };
    }
    {
      key = "<leader>ca";
      mode = ["n" "v"];
      action = ":lua vim.lsp.buf.code_action()<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Code Action";
      };
    }
    {
      key = "<leader>cr";
      mode = ["n"];
      action = ":lua vim.lsp.buf.rename()<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Rename Definition";
      };
    }
  ];
}
