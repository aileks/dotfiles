require("lazy").setup({
  { import = "plugins.lsp" },
  { import = "plugins.completion" },
  { import = "plugins.telescope" },
  { import = "plugins.treesitter" },
  { import = "plugins.git" },
  { import = "plugins.comments" },
  { import = "plugins.nvim-tree" },
  { import = "plugins.formatting" },
  { import = "plugins.ui" },
}, {
  install = {
    colorscheme = { "vague", "min-theme" },
  },
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
})
