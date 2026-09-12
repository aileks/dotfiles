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

local hl = vim.api.nvim_set_hl
hl(0, "Normal", { fg = cg.fg, bg = cg.bg })
hl(0, "NormalFloat", { fg = cg.fg, bg = cg.surface })
hl(0, "FloatBorder", { fg = cg.dim })
hl(0, "CursorLine", { bg = cg.surface })
hl(0, "CursorLineNr", { fg = cg.orange, bg = cg.surface, bold = true })
hl(0, "LineNr", { fg = cg.dim })
hl(0, "Comment", { fg = cg.dim, italic = true })
hl(0, "String", { fg = cg.green })
hl(0, "Visual", { bg = "#34312D" })
hl(0, "Search", { fg = cg.bg, bg = cg.orange })
hl(0, "CurSearch", { fg = cg.bg, bg = cg.orange, bold = true })
hl(0, "StatusLine", { fg = cg.fg, bg = cg.surface })
hl(0, "StatusLineNC", { fg = cg.dim, bg = cg.bg })
hl(0, "VertSplit", { fg = cg.dim })
hl(0, "Pmenu", { fg = cg.fg, bg = cg.surface })
hl(0, "PmenuSel", { fg = cg.bg, bg = cg.blue })
hl(0, "ErrorMsg", { fg = cg.red })
hl(0, "WarningMsg", { fg = cg.orange })
hl(0, "Yank", { fg = cg.bg, bg = cg.orange })

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "Yank", timeout = 200 })
  end,
})
