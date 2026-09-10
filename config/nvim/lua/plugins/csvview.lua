require('csvview').setup({})

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('config-csvview', { clear = true }),
  desc = 'Enable CSV view for delimited files',
  pattern = { 'csv', 'tsv' },
  callback = function()
    vim.cmd.CsvViewEnable()
  end,
})

vim.keymap.set('n', '<leader>uc', '<cmd>CsvViewToggle<cr>', { desc = 'Toggle CSV/TSV view' })
