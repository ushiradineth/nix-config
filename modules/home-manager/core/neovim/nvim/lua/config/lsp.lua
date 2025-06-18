local function merge(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

local function mappings(bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, merge({ desc = "Go to Definition" }, opts))
  vim.keymap.set({ "n", "v" }, "<leader>cf", vim.lsp.buf.references, merge({ desc = "Find References" }, opts))
  vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, merge({ desc = "Code Action" }, opts))
  vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, merge({ desc = "Rename Definition" }, opts))
end

local on_attach = function(client, bufnr)
  mappings(bufnr)
end

local servers = {
  rust_analyzer = {
    on_attach = function(_, bufnr)
      mappings(bufnr)
    end,
    settings = {
      ["rust-analyzer"] = {
        imports = {
          granularity = {
            group = "module",
          },
          prefix = "self",
        },
        cargo = {
          buildScripts = {
            enable = true,
          },
        },
        procMacro = {
          enable = true
        },
      }
    },
  },
  eslint = {
    on_attach = function(_, bufnr)
      mappings(bufnr)

      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        command = "EslintFixAll",
      })
    end,
    settings = {
      workingDirectory = { mode = "location" },
    },
    root_dir = vim.fs.dirname(vim.fs.find('.git', { path = root_dir, upward = true })[1]),
  },
  yamlls = {
    on_attach = function(_, bufnr)
      mappings(bufnr)

      if vim.bo[bufnr].filetype == "helm" then
        vim.schedule(function()
          vim.cmd("LspStop ++force yamlls")
        end)
      end
    end,
    settings = {
      yaml = {
        schemaStore = {
          enable = true,
          url = "https://www.schemastore.org/api/json/catalog.json",
        },
        schemas = {
          ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/all.json"] = "*.{yml,yaml}",
          ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/**/*.{yml,yaml}",
          ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
          ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
          ["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
          ["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
          ["http://json.schemastore.org/ansible-playbook"] = "*play*.{yml,yaml}",
          ["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
          ["https://json.schemastore.org/dependabot-v2"] = ".github/dependabot.{yml,yaml}",
          ["https://json.schemastore.org/gitlab-ci"] = "*gitlab-ci*.{yml,yaml}",
          ["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] =
          "*api*.{yml,yaml}",
          ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] =
          "*docker-compose*.{yml,yaml}",
          ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] =
          "*flow*.{yml,yaml}",
          ["https://api.bitbucket.org/schemas/pipelines-configuration"] = "*bitbucket-pipelines*.{yml,yaml}",
          ["values.schema.json"] = "values.yaml",
        },
        format = { enabled = true },
        validate = true,
        completion = true,
        hover = true,
      },
    },
  },
  helm_ls = {
    cmd       = { 'helm_ls', 'serve' },
    filetypes = { "helm", "yaml", 'yml' },
    root_dir  = vim.fs.dirname(vim.fs.find({ 'Chart.yaml' }, { upward = true })[1]),
    on_attach = on_attach,
  },
}

for server, config in pairs(servers) do
  vim.lsp.config(server, config)
end

-- Register servers with default settings
vim.lsp.config('*', {
  on_attach = function(client, bufnr)
    mappings(bufnr)
  end,
})

vim.lsp.set_log_level("off") -- Disable logging
