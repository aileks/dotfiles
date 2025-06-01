local opt = vim.opt
local g = vim.g
local cmd = vim.cmd

g.netrw_browse_split = 0
g.netrw_banner = 0
g.netrw_winsize = 25
opt.spell = true
opt.cmdheight = 0
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.number = true
opt.relativenumber = true
opt.title = true
opt.termguicolors = true
opt.ignorecase = true
opt.smartcase = true
opt.wrap = true
opt.breakindent = true
opt.linebreak = true
opt.list = true
opt.listchars = { tab = '▸ ', trail = '·' }
opt.fillchars:append({ eob = ' ' })
opt.mouse = 'a'
opt.mousemoveevent = true
opt.splitbelow = true
opt.splitright = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.clipboard = 'unnamedplus'
opt.confirm = true
opt.undofile = true
opt.backup = true
opt.backupdir:remove('.')
opt.shortmess:append({ I = true })
opt.wildmode = 'longest:full,full'
opt.completeopt = 'menuone,longest,preview'
opt.colorcolumn = '100'
opt.signcolumn = 'yes:2'
opt.showmode = false
opt.updatetime = 4001
opt.redrawtime = 10000
opt.exrc = true
opt.secure = true
opt.titlestring = '%f // nvim'
opt.smoothscroll = true

-- highlighted yank stuff
cmd [[
  augroup yank_highlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 200 })
  augroup END
]]

