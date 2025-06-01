return {
  {
    -- FORMATTER
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      quiet = true,
      formatters_by_ft = {
        javascript = { "prettier", "eslint_d" },
        typescript = { "prettier", "eslint_d" },
        javascriptreact = { "prettier", "eslint_d" },
        typescriptreact = { "prettier", "eslint_d" },
        astro = { "astro", "prettier", "eslint_d" },
        json = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        vue = { "prettier" },
        angular = { "prettier" },
        less = { "prettier" },
        flow = { "prettier" },
        sh = { "bash-language-server", "beautysh", "prettier" },
        bash = { "bash-language-server", "beautysh", "prettier" },
        zsh = { "bash-language-server", "beautysh", "prettier" },
        yaml = { "yamlls", "yamllint" },
        go = { "goimports", "gofmt" },
        terraform = { "terraform_fmt", "tfsec", "hclfmt" },
        hcl = { "hclfmt" },
        lua = { "stylua" },
        md = { "markdownlint" },
        rust = { "rustfmt" },
        php = { "php-cs-fixer" },
        ["_"] = { "trim_whitespace" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      notify_on_error = true,
      notify_no_formatters = true,
      format_on_save = function(bufnr)
        -- Disable autoformat for files in a certain path
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match("/node_modules/") then
          return
        end

        return { timeout_ms = 1000, lsp_fallback = true }
      end,
      format_after_save = { lsp_fallback = true },
    },
    config = function(_, opts)
      local conform = require("conform")
      conform.setup(opts)

      vim.keymap.set("n", "<leader>cf", function()
        conform.format({ timeout_ms = 1000, lsp_fallback = true })
      end, { noremap = true, silent = true, desc = "Format" })

      conform.formatters = {
        beautysh = {
          prepend_args = function()
            return { "--indent-size", "2", "--force-function-style", "fnpar" }
          end,
        },
      }
    end,
  },
}
