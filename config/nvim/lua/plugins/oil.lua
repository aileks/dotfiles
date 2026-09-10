require('oil').setup({
  default_file_explorer = true,
})

local map = vim.keymap.set

map('n', '<leader>e', '<cmd>Oil<CR>', { desc = 'File explorer' })
