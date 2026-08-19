local map = vim.keymap.set

map('n', '<leader>gg', '<cmd>LazyGit<cr>', { desc = 'Open LazyGit' })
map('n', '<leader>gf', '<cmd>LazyGitCurrentFile<cr>', { desc = 'LazyGit current file history' })
