-- bootstrapping
local wezterm = require 'wezterm'
local config = {}

-- actual config
config.font = wezterm.font('BerkeleyMono Nerd Font')
config.font_size = 14
config.color_scheme = 'Wez'
config.enable_tab_bar = false
config.window_background_opacity = 0.90
config.window_close_confirmation = 'NeverPrompt'
-- config.window_decorations = 'NONE'

return config
