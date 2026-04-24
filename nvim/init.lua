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
vim.opt.copyindent = true
vim.opt.preserveindent = true
vim.opt.whichwrap:append('<,>,h,l')
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.undofile = true
vim.opt.backup = true
vim.opt.mousemodel = 'extend'
vim.opt.errorbells = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.clipboard = 'unnamedplus'

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

vim.pack.add({
  { src = 'https://github.com/ficd0/ashen.nvim' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' },
  { src = 'https://github.com/YousefHadder/markdown-plus.nvim' },
})

require('ashen').setup({ transparent = true })
vim.cmd.colorscheme('ashen')

require('lualine').setup({
  options = {
    theme = 'auto',
    icons_enabled = false,
    component_separators = '|',
    section_separators = '',
  },
})

require('ibl').setup()

require('markdown-plus').setup()
