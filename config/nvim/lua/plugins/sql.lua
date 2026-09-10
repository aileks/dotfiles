vim.g.db_ui_use_nerd_fonts = 1
local username = vim.uv.os_get_passwd().username
vim.g.dbs = {
  ['local-postgres'] = string.format('postgresql://%s@127.0.0.1:5432/%s', username, username),
}

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('config-dadbod-completion', { clear = true }),
  desc = 'Enable database completion for SQL buffers',
  pattern = { 'sql', 'mysql', 'plsql', 'dbt' },
  callback = function(args)
    vim.bo[args.buf].omnifunc = 'vim_dadbod_completion#omni'
  end,
})

local map = vim.keymap.set

map('n', '<leader>Dt', '<cmd>DBUIToggle<CR>', { desc = 'Toggle DB UI' })
map('n', '<leader>Df', '<cmd>DBUIFindBuffer<CR>', { desc = 'Find buffer in DB UI' })
map('n', '<leader>Dr', '<cmd>DBUIRenameBuffer<CR>', { desc = 'Rename DB buffer' })
map('n', '<leader>Dl', '<cmd>DBUILastQueryInfo<CR>', { desc = 'Last query info' })
