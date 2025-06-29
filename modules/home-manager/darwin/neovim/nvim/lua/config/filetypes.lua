vim.filetype.add({
  extension = {
    mdx = "mdx",
  },
})

vim.filetype.add({
  pattern = {
    [".*/templates/.*%.yaml"] = "helm",
  },
})
