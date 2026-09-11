-- See https://wezfurlong.org/wezterm/

local wezterm = require 'wezterm'
local config = wezterm.config_builder and wezterm.config_builder() or {}

local settings = {
  ["colors"] = {
    ["ansi"] = {
      "#131210",
      "#B34A45",
      "#879B5C",
      "#D9A441",
      "#6785A1",
      "#9A788F",
      "#58918C",
      "#ACA49B"
    },
    ["background"] = "#131210",
    ["brights"] = {
      "#58534C",
      "#B34A45",
      "#879B5C",
      "#D9A441",
      "#6785A1",
      "#9A788F",
      "#58918C",
      "#DDD5CA"
    },
    ["cursor_bg"] = "#DDD5CA",
    ["cursor_border"] = "#DDD5CA",
    ["cursor_fg"] = "#131210",
    ["foreground"] = "#BBB3A9",
    ["scrollbar_thumb"] = "#58534C",
    ["selection_bg"] = "#3E3A34",
    ["selection_fg"] = "#DDD5CA",
    ["split"] = "#E17A3F",
    ["tab_bar"] = {
      ["active_tab"] = {
        ["bg_color"] = "#E17A3F",
        ["fg_color"] = "#131210"
      },
      ["background"] = "#131210",
      ["inactive_tab"] = {
        ["bg_color"] = "#1B1916",
        ["fg_color"] = "#9A938A"
      },
      ["inactive_tab_hover"] = {
        ["bg_color"] = "#23201C",
        ["fg_color"] = "#DDD5CA"
      },
      ["new_tab"] = {
        ["bg_color"] = "#131210",
        ["fg_color"] = "#9A938A"
      },
      ["new_tab_hover"] = {
        ["bg_color"] = "#23201C",
        ["fg_color"] = "#DDD5CA"
      }
    }
  },
  ["default_gui_startup_args"] = {
    "connect",
    "unix"
  },
  ["enable_wayland"] = false,
  ["font"] = (wezterm.font("IosevkaTerm Nerd Font", { weight = "Regular" })),
  ["font_rules"] = {
    {
      ["font"] = (wezterm.font("IosevkaTerm Nerd Font", { weight = "Bold", style = "Italic" })),
      ["intensity"] = "Bold",
      ["italic"] = true
    },
    {
      ["font"] = (wezterm.font("IosevkaTerm Nerd Font", { weight = "Bold" })),
      ["intensity"] = "Bold",
      ["italic"] = false
    },
    {
      ["font"] = (wezterm.font("IosevkaTerm Nerd Font", { weight = "Regular", style = "Italic" })),
      ["italic"] = true
    },
    {
      ["font"] = (wezterm.font("IosevkaTerm Nerd Font", { weight = "Regular" })),
      ["italic"] = false
    }
  },
  ["font_size"] = 14,
  ["hide_tab_bar_if_only_one_tab"] = false,
  ["scrollback_lines"] = 10000,
  ["tab_and_split_indices_are_zero_based"] = false,
  ["unix_domains"] = {
    {
      ["name"] = "unix",
      ["socket_path"] = (os.getenv("XDG_RUNTIME_DIR") .. "/wezterm-mux.sock")
    }
  },
  ["use_fancy_tab_bar"] = false,
  ["window_background_opacity"] = 0.95,
  ["window_close_confirmation"] = "NeverPrompt",
  ["window_decorations"] = "NONE"
}
for k, v in pairs(settings) do
  config[k] = v
end


assert(loadfile((os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/wezterm/mux.lua"))(wezterm, config)
return config
