local todo = require('todo-comments')

todo.setup({
  keywords = {
    TODO = { color = 'warning' },
    PERF = { color = 'hint' },
    NOTE = { color = 'info' },
  },
  colors = {
    test = { '@label', 'Identifier' },
  },
  -- default patterns require a colon after the keyword; match bare keywords too
  highlight = {
    -- "wide" extends past keywords at end of line and trips Neovim's extmark bounds check
    keyword = 'bg',
    pattern = [[.*<(KEYWORDS)>]],
  },
  search = {
    pattern = [[\b(KEYWORDS)\b]],
  },
})

vim.keymap.set('n', ']t', todo.jump_next, { desc = 'Next todo comment' })
vim.keymap.set('n', '[t', todo.jump_prev, { desc = 'Previous todo comment' })
vim.keymap.set('n', '<leader>ft', '<cmd>TodoFzfLua<CR>', { desc = 'Todo comments' })
