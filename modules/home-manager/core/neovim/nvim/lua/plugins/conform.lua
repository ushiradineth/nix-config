return {
  {
    -- FORMATTER
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      quiet = true,
      formatters_by_ft = {
        javascript = { "biome", "prettier", stop_after_first = true },
        typescript = { "biome", "prettier", stop_after_first = true },
        javascriptreact = { "biome", "prettier", stop_after_first = true },
        typescriptreact = { "biome", "prettier", stop_after_first = true },
        astro = { "biome" },
        json = { "biome" },
        jsonc = { "biome" },
        html = { "biome" },
        css = { "biome" },
        markdown = { "markdownlint", "prettier", stop_after_first = true },
        md = { "markdownlint", "prettier", stop_after_first = true },
        sh = { "beautysh", "prettier", stop_after_first = true },
        bash = { "beautysh", "prettier", stop_after_first = true },
        zsh = { "beautysh", "prettier", stop_after_first = true },
        yaml = { "yamlfix" },
        go = { "goimports-reviser", "gofumpt" },
        terraform = { "terraform_fmt" },
        lua = { "stylua" },
        rust = { "rustfmt" },
        php = { "pretty-php" },
        nix = { "alejandra" },
        ["_"] = { "trim_whitespace" },
      },
      formatters = {
        biome = {
          require_cwd = true,
        },
        yamlfix = {
          env = {
            YAMLFIX_WHITELINES = "1",
          },
        },
        beautysh = {
          prepend_args = function()
            return { "--indent-size", "2", "--force-function-style", "fnpar" }
          end,
        },
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
    end,
  },
}
