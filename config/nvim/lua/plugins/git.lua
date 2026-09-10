require('gitsigns').setup({
  signs = {
    add = { text = '│' },
    change = { text = '│' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
    untracked = { text = '┆' },
  },
})

local map = vim.keymap.set

map('n', ']h', function()
  require('gitsigns').nav_hunk('next')
end, { desc = 'Next hunk' })
map('n', '[h', function()
  require('gitsigns').nav_hunk('prev')
end, { desc = 'Previous hunk' })

map('n', '<leader>ghs', function()
  require('gitsigns').stage_hunk()
end, { desc = 'Stage hunk' })
map('n', '<leader>ghr', function()
  require('gitsigns').reset_hunk()
end, { desc = 'Reset hunk' })
map('n', '<leader>ghp', function()
  require('gitsigns').preview_hunk()
end, { desc = 'Preview hunk' })
map('n', '<leader>ghb', function()
  require('gitsigns').blame_line({ full = true })
end, { desc = 'Blame line' })
map('n', '<leader>gB', function()
  require('gitsigns').toggle_current_line_blame()
end, { desc = 'Toggle line blame' })
map('n', '<leader>gd', function()
  require('gitsigns').diffthis()
end, { desc = 'Diff against index' })
map('v', '<leader>ghs', function()
  require('gitsigns').stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
end, { desc = 'Stage hunk' })
