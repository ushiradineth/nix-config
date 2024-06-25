return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require "null-ls"
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
    local on_attach = function(client, bufnr)
      if client.supports_method "textDocument/formatting" then
        vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = augroup,
          buffer = bufnr,
          callback = function() vim.lsp.buf.format { async = false } end,
        })
      end
    end

    null_ls.setup {
      sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.prettierd,
        null_ls.builtins.diagnostics.eslint_d,
      },
      on_attach = on_attach,
    }

    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
  end,
}
