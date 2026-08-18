vim.g.db_ui_use_nerd_fonts = 1

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'sql', 'mysql', 'plsql' },
  callback = function(args)
    vim.bo[args.buf].omnifunc = 'vim_dadbod_completion#omni'
  end,
})

local map = vim.keymap.set

map('n', '<leader>dbt', '<cmd>DBUIToggle<CR>', { desc = 'Toggle DB UI' })
map('n', '<leader>dbf', '<cmd>DBUIFindBuffer<CR>', { desc = 'Find buffer in DB UI' })
map('n', '<leader>dbr', '<cmd>DBUIRenameBuffer<CR>', { desc = 'Rename DB buffer' })
map('n', '<leader>dbl', '<cmd>DBUILastQueryInfo<CR>', { desc = 'Last query info' })
