require('csvview').setup({})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'csv', 'tsv' },
  callback = function()
    vim.cmd.CsvViewEnable()
  end,
})

vim.keymap.set('n', '<leader>uc', '<cmd>CsvViewToggle<cr>', { desc = 'Toggle CSV/TSV view' })
