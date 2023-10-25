-- Set leader (space)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Move by term rows instead of lines for wrapped text
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Better window switching
vim.keymap.set('n', '<leader>w', '<C-w>')

-- Reselect visual selection after indenting
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Maintain cursor position when yanking
vim.keymap.set('v', 'y', "myy`y")

-- Disable annoying command line typo
vim.keymap.set('n', 'q:', ':q')

-- Paste replace visual selection without copying it
vim.keymap.set('v', 'p', '"_dP')
vim.keymap.set('n', 'p', '"_dP')

-- Easy insertion of a trailing ; or , from insert mode
vim.keymap.set('i', ';;', '<Esc>A;')
vim.keymap.set('i', ',,', '<Esc>A,')
vim.keymap.set('n', ';;', 'A;<Esc>')
vim.keymap.set('n', ',,', 'A,<Esc>')

-- Clear search highlighting
vim.keymap.set('n', '<Leader>k', ':nohlsearch<CR>')

-- Open the current file in the default program
vim.keymap.set('n', '<Leader>x', ':!xdg-open %<CR><CR>')

-- Move lines up and down
vim.keymap.set('i', '<A-j>', '<Esc>:move .+1<CR>==gi')
vim.keymap.set('i', '<A-k>', '<Esc>:move .-2<CR>==gi')
vim.keymap.set('n', '<A-j>', ':move .+1<CR>==')
vim.keymap.set('n', '<A-k>', ':move .-2<CR>==')
vim.keymap.set('v', '<A-j>', ":move '>+1<CR>gv=gv")
vim.keymap.set('v', '<A-k>', ":move '<-2<CR>gv=gv")

-- Create a new file
vim.keymap.set('n', '<Leader>n', ':enew<CR>')

-- Plugins
vim.keymap.set('n', '<Leader>L', ':Lazy<CR>')
vim.keymap.set('n', '<Leader>Ls', ':Lazy sync<CR>')
vim.keymap.set('n', '<Leader>Lu', ':Lazy update<CR>')
