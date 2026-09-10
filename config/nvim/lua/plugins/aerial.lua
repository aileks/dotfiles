require('aerial').setup({
  layout = {
    default_direction = 'prefer_right',
  },
})

local map = vim.keymap.set

map('n', '<leader>uo', '<cmd>AerialToggle!<CR>', { desc = 'Code outline' })
