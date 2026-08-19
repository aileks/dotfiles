require('overseer').setup({})

local map = vim.keymap.set

map('n', '<leader>or', '<cmd>OverseerRun<cr>', { desc = 'Run task from template' })
map('n', '<leader>oR', '<cmd>OverseerRunCmd<cr>', { desc = 'Run shell command as task' })
map('n', '<leader>ot', '<cmd>OverseerToggle<cr>', { desc = 'Toggle task list' })
map('n', '<leader>oa', '<cmd>OverseerQuickAction<cr>', { desc = 'Run quick action (restart)' })
