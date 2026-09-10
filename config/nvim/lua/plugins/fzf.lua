local fzf = require('fzf-lua')

fzf.setup({
  ui_select = {},
  fzf = { colorscheme = 'cinder-grove' },
  winopts = { preview = { default = 'bat' } },
})

local map = vim.keymap.set

map('n', '<leader>ff', '<cmd>FzfLua files<CR>', { desc = 'Find files' })
map('n', '<leader>fg', '<cmd>FzfLua live_grep<CR>', { desc = 'Grep project' })
map('n', '<leader>fw', '<cmd>FzfLua grep_cword<CR>', { desc = 'Grep word under cursor' })
map('n', '<leader>fb', '<cmd>FzfLua buffers<CR>', { desc = 'Buffers' })
map('n', '<leader>fo', '<cmd>FzfLua oldfiles<CR>', { desc = 'Recent files' })
map('n', '<leader>fh', '<cmd>FzfLua helptags<CR>', { desc = 'Help tags' })
map('n', '<leader>fc', '<cmd>FzfLua command_history<CR>', { desc = 'Command history' })
map('n', '<leader>fm', '<cmd>FzfLua marks<CR>', { desc = 'Marks' })
map('n', '<leader>fd', '<cmd>FzfLua diagnostics_document<CR>', { desc = 'Document diagnostics' })
map('n', '<leader>fD', '<cmd>FzfLua diagnostics_workspace<CR>', { desc = 'Workspace diagnostics' })
map('n', '<leader>fr', '<cmd>FzfLua lsp_references<CR>', { desc = 'LSP references' })
map('n', '<leader>fs', '<cmd>FzfLua lsp_document_symbols<CR>', { desc = 'Document symbols' })
map('n', '<leader>fS', '<cmd>FzfLua lsp_workspace_symbols<CR>', { desc = 'Workspace symbols' })
map('n', '<leader>gf', '<cmd>FzfLua git_files<CR>', { desc = 'Git files' })
map('n', '<leader>gs', '<cmd>FzfLua git_status<CR>', { desc = 'Git status' })
map('n', '<leader>gc', '<cmd>FzfLua git_commits<CR>', { desc = 'Git commits' })
map('n', '<leader>gb', '<cmd>FzfLua git_branches<CR>', { desc = 'Git branches' })
