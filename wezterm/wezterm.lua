local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("BerkeleyMono Nerd Font Mono")
-- Alternative: config.font = wezterm.font("AdwaitaMono Nerd Font Mono")
config.font_size = 12.0
config.colors = require("ashen")

config.window_background_opacity = 0.95
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false

config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"

config.audible_bell = "Disabled"
config.scrollback_lines = 10000

return config
