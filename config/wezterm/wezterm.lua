local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font 'IosevkaTerm Nerd Font'
config.font_size = 14
config.scrollback_lines = 10000

config.colors = {
  foreground = '#BBB3A9',
  background = '#131210',
  cursor_bg = '#DDD5CA',
  cursor_border = '#DDD5CA',
  cursor_fg = '#131210',
  selection_bg = '#3E3A34',
  selection_fg = '#DDD5CA',
  scrollbar_thumb = '#58534C',
  split = '#E17A3F',

  ansi = {
    '#131210',
    '#B34A45',
    '#879B5C',
    '#D9A441',
    '#6785A1',
    '#9A788F',
    '#58918C',
    '#ACA49B',
  },

  brights = {
    '#58534C',
    '#B34A45',
    '#879B5C',
    '#D9A441',
    '#6785A1',
    '#9A788F',
    '#58918C',
    '#DDD5CA',
  },

  tab_bar = {
    background = '#131210',
    active_tab = {
      bg_color = '#E17A3F',
      fg_color = '#131210',
    },
    inactive_tab = {
      bg_color = '#1B1916',
      fg_color = '#9A938A',
    },
    inactive_tab_hover = {
      bg_color = '#23201C',
      fg_color = '#DDD5CA',
    },
    new_tab = {
      bg_color = '#131210',
      fg_color = '#9A938A',
    },
    new_tab_hover = {
      bg_color = '#23201C',
      fg_color = '#DDD5CA',
    },
  },
}

config.use_fancy_tab_bar = false
config.window_background_opacity = 0.97
config.window_close_confirmation = 'NeverPrompt'
config.window_decorations = 'NONE'
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

config.unix_domains = {
  {
    name = 'unix',
    socket_path = os.getenv('XDG_RUNTIME_DIR') .. '/wezterm-mux.sock',
  },
}
config.default_gui_startup_args = { 'connect', 'unix' }

require('mux').apply_to_config(config)

return config
