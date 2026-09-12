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

local cg = {
  bg = "#131210",
  surface = "#1B1916",
  fg = "#BBB3A9",
  bright = "#DDD5CA",
  dim = "#58534C",
  orange = "#E17A3F",
  green = "#879B5C",
  blue = "#6785A1",
  red = "#B34A45",
}

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
