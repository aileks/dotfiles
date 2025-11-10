vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.showmatch = true
vim.opt.whichwrap:append("<,>,h,l")
vim.opt.clipboard = "unnamedplus"
vim.opt.timeout = true
vim.opt.timeoutlen = 500
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.cmdheight = 1
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.shortmess:append("c")
vim.opt.completeopt = { "menuone", "noselect" }
vim.opt.background = "dark"
