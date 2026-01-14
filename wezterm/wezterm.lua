local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Alternative: config.font = wezterm.font("AdwaitaMono Nerd Font Mono")
config.font = wezterm.font("BerkeleyMono Nerd Font Mono")
config.font_size = 14.0
config.colors = require("ashen")
config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.window_background_opacity = 0.9
config.audible_bell = "Disabled"
config.scrollback_lines = 10000
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

return config
