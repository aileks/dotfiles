local alpha = require('alpha')
local dashboard = require('alpha.themes.dashboard')
local plugins = #vim.tbl_keys(require("lazy").plugins())
local v = vim.version()
local datetime = os.date " %m-%d-%Y   %H:%M:%S"
local nvim = ""

dashboard.section.header.val = {
    "                                                              ",
    "                          ,--,                   ,-.          ",
    "               ,--,   ,--.'|               ,--/ /|            ",
    "             ,--.'|   |  | :             ,--. :/ |            ",
    "             |  |,    :  : '             :  : ' /  .--.--.    ",
    "   ,--.--.   `--'_    |  ' |      ,---.  |  '  /  /  /    '   ",
    "  /       \\  ,' ,'|   '  | |     /     \\ '  |  : |  :  /`./   ",
    " .--.  .-. | '  | |   |  | :    /    /  ||  |   \\|  :  ;_     ",
    "  \\__\\/: . . |  | :   '  : |__ .    ' / |'  : |. \\  \\    `.  ",
    "  ,\" .--.; | '  : |__ |  | '.'|'   ;   /||  | ' \\ \\`----.   \\ ",
    " /  /  ,.  | |  | '.'|;  :    ;'   |  / |'  : |--'/  /`--'  / ",
    ";  :   .'   \\;  :    ;|  ,   / |   :    |;  |,'  '--'.     /  ",
    "|  ,     .-./|  ,   /  ---`-'   \\   \\  / '--'      `--'---'   ",
    " `--`---'     ---`-'             `----'                       ",
    "                                                              ",
    "                                                              ",
  string.format("            󰂖 %d  %s %d.%d.%d  %s", plugins, nvim, v.major, v.minor, v.patch, datetime)
}

dashboard.section.buttons.val = {
    dashboard.button( 'SPC  n', '  New file' , ':enew'),
    dashboard.button( 'SPC fh', '  Recent files'   , ':Telescope oldfiles<CR>'),
    dashboard.button( 'SPC ff', '  Find file', ':Telescope find_files<CR>'),
    dashboard.button( 'SPC fg', '󰈭  Find word', ':Telescope live_grep<CR>'),
    dashboard.button( ':q', '  Quit', ':q'),
}

dashboard.section.footer.opts.hl = "AlphaFooter"
dashboard.section.header.opts.hl = "AlphaHeader"
dashboard.section.buttons.opts.hl = "MoreMsg"

alpha.setup(dashboard.opts)

vim.cmd([[
    autocmd FileType alpha setlocal nofoldenable
]])
