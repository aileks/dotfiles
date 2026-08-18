local trouble = require('trouble')

trouble.setup({})

local map = vim.keymap.set

map('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<CR>', { desc = 'Workspace diagnostics' })
map('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>', { desc = 'Document diagnostics' })
map('n', '<leader>xL', '<cmd>Trouble loclist toggle<CR>', { desc = 'Location list' })
map('n', '<leader>xQ', '<cmd>Trouble qflist toggle<CR>', { desc = 'Quickfix' })
map('n', '<leader>xs', '<cmd>Trouble symbols toggle<CR>', { desc = 'Symbols' })

map('n', '<leader>xR', '<cmd>Trouble lsp toggle<CR>', { desc = 'LSP references/items' })
