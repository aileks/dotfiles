require('glance').setup({
  use_trouble_qf = true,
})

local map = vim.keymap.set

map('n', 'gR', '<cmd>Glance references<CR>', { desc = 'Peek references' })
map('n', 'gY', '<cmd>Glance type_definitions<CR>', { desc = 'Peek type definitions' })
map('n', 'gM', '<cmd>Glance implementations<CR>', { desc = 'Peek implementations' })
