local keymap = vim.keymap

-- General keymaps
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
keymap.set("n", "<ESC>", ":nohl<CR>", { desc = "Clear search highlights" })

-- Window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- Tab management
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })

-- Buffer navigation
keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

-- Keep selection highlighted after indent
keymap.set('v', '<', '<gv')
keymap.set('v', '>', '>gv')

-- Yank without jank
keymap.set('v', 'y', 'myy`y')
keymap.set('v', 'Y', 'myY`y')

-- Move between wrapped lines
keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Better paste
keymap.set('v', 'p', '"_dP')

-- Move selection easier
keymap.set('i', '<A-j>', '<Esc>:move .+1<CR>==gi', { silent = true })
keymap.set('i', '<A-k>', '<Esc>:move .-2<CR>==gi', { silent = true })
keymap.set('n', '<A-j>', ':move .+1<CR>==', { silent = true })
keymap.set('n', '<A-k>', ':move .-2<CR>==', { silent = true })
keymap.set('v', '<A-j>', ":move '>+1<CR>gv=gv", { silent = true })
keymap.set('v', '<A-k>', ":move '<-2<CR>gv=gv", { silent = true })

-- Niceties for movement
keymap.set('n', 'n', 'nzzzv')
keymap.set('n', 'N', 'Nzzzv')
keymap.set('n', '<C-u>', '<C-u>zz')
keymap.set('n', '<C-d>', '<C-d>zz')

-- Disable Q
keymap.set("n", "Q", "<nop>")

-- Open netrw
keymap.set('n', '<leader>e', vim.cmd.Lex)

-- Easier save & quit
keymap.set('n', '<leader>w', vim.cmd.w)
keymap.set('n', '<leader>W', vim.cmd.wall)
keymap.set('n', '<leader>q', vim.cmd.q)
