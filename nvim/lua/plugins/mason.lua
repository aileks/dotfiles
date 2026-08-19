require('mason').setup({
  PATH = 'prepend',
})

require('mason-lspconfig').setup({
  ensure_installed = { 'basedpyright', 'ruff', 'vtsls', 'jsonls', 'yamlls', 'lua_ls' },
  automatic_enable = { exclude = { 'stylua' } },
})

require('mason-tool-installer').setup({
  ensure_installed = {
    'debugpy',
    'prettier',
    'eslint_d',
    'js-debug-adapter',
    'sqlfluff',
    'stylua',
    'shfmt',
    'tree-sitter-cli',
  },
  run_on_start = true,
  auto_update = false,
  debounce_hours = 24,
})
