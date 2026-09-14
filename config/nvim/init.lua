local opt = vim.opt

opt.number = true
opt.cursorline = true
opt.scrolloff = 8
opt.termguicolors = true
opt.showmode = false
opt.signcolumn = "yes"
opt.mouse = "a"
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.undofile = true
opt.swapfile = false
opt.clipboard = "unnamedplus"
opt.splitbelow = true
opt.splitright = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.wildmenu = true
opt.statusline = " %f %m%r%= %l:%c "

vim.pack.add({
  "https://github.com/aileks/cinder-grove.nvim"
})

require("cinder-grove").setup({
  transparent = true,
})

vim.cmd.colorscheme('cinder-grove')

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "Yank", timeout = 200 })
  end,
})
