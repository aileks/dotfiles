local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("CommitMono Nerd Font Mono")
config.font_size = 16
config.colors = require("ashen")
config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.window_background_opacity = 0.95
config.audible_bell = "Disabled"
config.scrollback_lines = 10000
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

return config
