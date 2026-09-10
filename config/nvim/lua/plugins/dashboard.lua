local alpha = require('alpha')
local dashboard = require('alpha.themes.dashboard')

dashboard.section.header.val = {
  '                                                     ',
  '  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ',
  '  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ',
  '  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ',
  '  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ',
  '  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ',
  '  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ',
  '                                                     ',
}

dashboard.section.buttons.val = {
  dashboard.button('f', '  Find file', '<cmd>FzfLua files<CR>'),
  dashboard.button('g', '  Find text', '<cmd>FzfLua live_grep<CR>'),
  dashboard.button('r', '  Recent files', '<cmd>FzfLua oldfiles<CR>'),
  dashboard.button('n', '  New file', '<cmd>ene<CR>'),
  dashboard.button('s', '  Restore session', "<cmd>lua require('persistence').load()<CR>"),
  dashboard.button('q', '  Quit', '<cmd>qa<CR>'),
}

local version = vim.version()
dashboard.section.footer.val = ('Neovim %d.%d.%d'):format(version.major, version.minor, version.patch)

alpha.setup(dashboard.config)
