-- Bootstrapping
local wezterm = require 'wezterm'
local config = {}

-- Actual Config
config.font = wezterm.font('BerkeleyMono Nerd Font')
config.font_size = 16
config.color_scheme = 'rose-pine'
config.enable_tab_bar = false
config.window_background_opacity = 0.95
config.window_close_confirmation = 'NeverPrompt'
config.window_decorations = 'NONE'

return config
