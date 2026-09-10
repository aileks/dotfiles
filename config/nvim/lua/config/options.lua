vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.termguicolors = true
vim.opt.showtabline = 2
vim.opt.wildmode = 'longest:full,full'
vim.opt.linebreak = true
vim.opt.showbreak = '...'
vim.opt.list = true
vim.opt.listchars = { tab = '→ ', trail = '·', nbsp = '␣' }
vim.opt.pumheight = 10
vim.opt.shortmess:append('c')
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.whichwrap:append('<,>,h,l')
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.undofile = true
vim.opt.backup = true
vim.opt.backupdir:remove('.')
vim.opt.confirm = true
vim.opt.mousemodel = 'extend'
vim.opt.errorbells = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.signcolumn = 'yes'
vim.opt.winborder = 'single'
