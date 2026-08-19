local conform = require('conform')

conform.setup({
  formatters_by_ft = {
    python = { 'ruff_organize_imports', 'ruff_format' },
    javascript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
    json = { 'prettier' },
    yaml = { 'prettier' },
    html = { 'prettier' },
    css = { 'prettier' },
    markdown = { 'prettier' },
    sql = { 'sqlfluff' },
    sh = { 'shfmt' },
    lua = { 'stylua' },
  },
  format_on_save = {
    timeout_ms = 3000,
    lsp_format = 'fallback',
  },
})

vim.keymap.set('n', '<leader>lf', function()
  conform.format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format buffer' })
