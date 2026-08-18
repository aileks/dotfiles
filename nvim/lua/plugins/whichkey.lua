local wk = require('which-key')
wk.setup({
  preset = 'modern',
  icons = { rules = false },
})

wk.add({
  { '<leader>b', group = 'buffer' },
  { '<leader>f', group = 'find' },
  { '<leader>g', group = 'git' },
  { '<leader>l', group = 'lsp' },
  { '<leader>d', group = 'debug' },
  { '<leader>t', group = 'test' },
  { '<leader>db', group = 'buffers' },
})
