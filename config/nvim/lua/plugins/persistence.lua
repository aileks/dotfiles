local persistence = require('persistence')

persistence.setup({})

local map = vim.keymap.set

map('n', '<leader>ss', function()
  persistence.load()
end, { desc = 'Restore session for cwd' })
map('n', '<leader>sl', function()
  persistence.load({ last = true })
end, { desc = 'Restore last session' })
map('n', '<leader>sd', function()
  persistence.stop()
end, { desc = 'Stop session saving' })
