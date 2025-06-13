-- Bootstrapping
local wezterm = require("wezterm")
local config = {}

-- Actual Config
config.font = wezterm.font("BerkeleyMono Nerd Font")
config.font_size = 16
config.color_scheme = "Gruvbox dark, hard (base16)"
config.enable_tab_bar = false
config.enable_wayland = false
config.window_background_opacity = 0.95
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "NONE"
config.xcursor_theme = "Capitaine Cursors (Gruvbox)"

return config
