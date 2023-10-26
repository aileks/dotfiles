-- Tabs as spaces
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

-- Some nice-to-haves
vim.opt.smartindent = true
vim.opt.wrap = true

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Better tab completion for commands
vim.opt.wildmode = 'longest:full,full'
vim.opt.completeopt = 'menuone,longest,preview'

-- Filename and working directory title
vim.opt.title = true

-- Enable mouse
vim.opt.mouse = 'a'
vim.opt.mousemoveevent = true

-- Term colors
vim.opt.termguicolors = true

-- Better searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Showing invisible characters (useful for trailing whitespace)
vim.opt.list = true
vim.opt.listchars = { tab = "▸ ", trail = '·' }

-- Gets rid of the ~ character at the end of buffers
vim.opt.fillchars:append({ eob = ' '})

-- Split to the right or below the current buffer
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Keeps cursor 8 lines below or above while scrolling
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Use system clipboard
vim.opt.clipboard = 'unnamedplus'

-- Ask for confirmation instead of erroring while exiting
vim.opt.confirm = true

-- Persistent undo
vim.opt.undofile = true

-- Backups
vim.opt.backup = true
vim.opt.backupdir:remove('.')

-- Underline spelling errors
vim.opt.spell = true

-- Fix HTML snippets in PHP files
vim.cmd[[
    au BufRead *.php set ft=php.html
    au BufNewFile *.php set ft=php.html
]]
