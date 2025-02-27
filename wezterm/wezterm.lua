-- bootstrapping
local wezterm = require 'wezterm'
local config = {}

-- actual config
config.font = wezterm.font('BerkeleyMono Nerd Font')
config.font_size = 14
config.color_scheme = 'rose-pine'
config.enable_tab_bar = false
config.window_background_opacity = 0.97
config.window_close_confirmation = 'NeverPrompt'
config.window_decorations = 'NONE'

return config
