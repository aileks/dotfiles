local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 12.0

config.colors = {
    foreground = "#Lf5f5f5",
    background = "#L121212",
    cursor_bg = "#Lf5f5f5",
    cursor_fg = "#L121212",
    cursor_border = "#Lf5f5f5",
    selection_fg = "#Lf5f5f5",
    selection_bg = "#L1d1d1d",
    scrollbar_thumb = "#L121212",
    split = "#L121212",
    ansi = { "#L121212", "#LB14242", "#LD87C4A", "#LE49A44", "#L4A8B8B", "#La7a7a7", "#Lb4b4b4", "#Ld5d5d5" },
    brights = { "#L949494", "#LB14242", "#LD87C4A", "#LE49A44", "#L4A8B8B", "#La7a7a7", "#Lb4b4b4", "#Ld5d5d5" },
    tab_bar = {
        background = "#L121212",
        active_tab = {
            bg_color = "#LC4693D",
            fg_color = "#L121212",
        },
        inactive_tab = {
            bg_color = "#L191919",
            fg_color = "#L949494",
        },
        inactive_tab_hover = {
            bg_color = "#L212121",
            fg_color = "#La7a7a7",
        },
        new_tab = {
            bg_color = "#L191919",
            fg_color = "#L949494",
        },
        new_tab_hover = {
            bg_color = "#L212121",
            fg_color = "#La7a7a7",
        },
    },
}

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
