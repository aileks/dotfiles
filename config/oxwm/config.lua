---@module 'oxwm'

local colors = {
	background = "#131210",
	bright = "#DDD5CA",
	muted = "#58534C",
	orange = "#E17A3F",
	red = "#B34A45",
	green = "#879B5C",
	blue = "#6785A1",
	purple = "#9A788F",
	cyan = "#58918C",
}

local mod = { "Mod4" }
local shift = { "Mod4", "Shift" }
local ctrl = { "Mod4", "Control" }
local ctrl_shift = { "Mod4", "Control", "Shift" }
local separator = { oxwm.bar.block.static({ text = "│", color = colors.muted }) }
local blocks = {
	oxwm.bar.block.shell({
		command = "bar-dnd",
		format = "{}",
		interval = 5,
		color = colors.orange,
		click = "dnd-toggle",
		underline = false,
	}),
	separator[1],
	oxwm.bar.block.shell({
		command = "bar-volume",
		format = "{}",
		interval = 5,
		color = colors.purple,
		click = "audio sink mute",
		underline = false,
	}),
	separator[1],
	oxwm.bar.block.shell({
		command = "bar-cpu-temperature",
		format = "{}",
		interval = 5,
		color = colors.blue,
		click = "wezterm start --always-new-process -- btop",
		underline = false,
	}),
	separator[1],
	oxwm.bar.block.ram({
		format = " {used} GB",
		interval = 5,
		color = colors.blue,
		click = "wezterm start --always-new-process -- btop",
		underline = false,
	}),
	separator[1],
	oxwm.bar.block.shell({
		command = "bar-gpu",
		format = "{}",
		interval = 5,
		color = colors.green,
		click = "wezterm start --always-new-process -- nvtop",
		underline = false,
	}),
	separator[1],
	oxwm.bar.block.shell({
		command = "bar-network",
		format = "{}",
		interval = 5,
		color = colors.cyan,
		click = "nm-connection-editor",
		underline = false,
	}),
	separator[1],
	oxwm.bar.block.datetime({
		format = " {}",
		date_format = "%b %d %H:%M",
		interval = 1,
		color = colors.bright,
		underline = false,
	}),
	separator[1],
	oxwm.bar.block.systray({}),
}
oxwm.bar.set_blocks(blocks)

oxwm.bar.set_scheme_normal(colors.muted, colors.background, colors.muted)
oxwm.bar.set_scheme_occupied(colors.bright, colors.background, colors.orange)
oxwm.bar.set_scheme_selected(colors.orange, colors.background, colors.orange)
oxwm.bar.set_scheme_urgent(colors.bright, colors.red, colors.red)

oxwm.set_terminal("wezterm")
oxwm.set_modkey("Mod4")
oxwm.set_tags({ "1", "2", "3", "4", "5", "6", "7" })
oxwm.set_layout("tiling")
oxwm.set_attach_method("top")
oxwm.set_floating_position("center")
oxwm.set_layout_symbol("tiling", "[T]")
oxwm.set_layout_symbol("normie", "[F]")

oxwm.border.set_width(2)
oxwm.border.set_focused_color(colors.orange)
oxwm.border.set_unfocused_color(colors.muted)

oxwm.gaps.set_enabled(true)
oxwm.gaps.set_inner(6, 6)
oxwm.gaps.set_outer(12, 12)

oxwm.bar.set_font("Iosevka Nerd Font Propo:style=Medium:size=10")
oxwm.bar.set_position("top")

for _, class in ipairs({
	"imv",
	"Qalculate-gtk",
	"Blueman",
	"Bitwarden",
	"bitwarden",
	"localsend",
	"polkit-gnome",
	"xdg-desktop-portal-gtk",
	"Nm-connection-editor",
}) do
	oxwm.rule.add({ class = class, floating = true })
end

local launchers = {
	{ mod, "Return", "wezterm connect unix" },
	{ mod, "T", "wezterm-workspaces" },
	{ mod, "Space", "rofi -show drun" },
	{ mod, "X", "emacsclient -c -a ''" },
	{ mod, "W", "zen-browser" },
	{ mod, "S", "signal-desktop --ignore-gpu-blocklist --enable-features=AcceleratedVideoDecodeLinuxGL --use-gl=desktop" },
	{ mod, "E", "wezterm start --always-new-process -- yazi" },
	{ mod, "A", "wezterm start --always-new-process -- wiremix" },
	{ mod, "O", "region-ocr" },
	{ mod, "V", "clipmenu" },
	{ mod, "semicolon", "bemoji -n" },
	{ mod, "Equal", "qalculate-gtk" },
	{ mod, "Escape", "lock-session" },
	{ mod, "N", "dnd-toggle" },
	{ ctrl_shift, "N", "dunstctl context" },
	{ shift, "P", "power-menu" },
	{ mod, "R", "screenrecord menu" },
	{ ctrl, "R", "screenrecord stop" },
	{ mod, "Print", "screenrecord region" },
	{ shift, "Print", "screenrecord output" },
	{ {}, "Print", "screenshot region" },
	{ { "Control" }, "Print", "screenshot window" },
	{ { "Shift" }, "Print", "screenshot full" },
	{ {}, "XF86AudioPlay", "playerctl play-pause" },
	{ {}, "XF86AudioPause", "playerctl play-pause" },
	{ {}, "XF86AudioNext", "playerctl next" },
	{ {}, "XF86AudioPrev", "playerctl previous" },
	{ {}, "XF86AudioRaiseVolume", "audio sink up" },
	{ {}, "XF86AudioLowerVolume", "audio sink down" },
	{ {}, "XF86AudioMute", "audio sink mute" },
	{ {}, "XF86AudioMicMute", "audio source mute" },
	{ {}, "XF86MonBrightnessUp", "brightness up" },
	{ {}, "XF86MonBrightnessDown", "brightness down" },
}

for _, binding in ipairs(launchers) do
	oxwm.key.bind(binding[1], binding[2], oxwm.spawn(binding[3]))
end

oxwm.key.bind(mod, "Q", oxwm.client.kill())
oxwm.key.bind(mod, "F", oxwm.client.toggle_fullscreen())
oxwm.key.bind(shift, "Space", oxwm.client.toggle_floating())
oxwm.key.bind(mod, "J", oxwm.client.focus_stack(1))
oxwm.key.bind(mod, "K", oxwm.client.focus_stack(-1))
oxwm.key.bind(shift, "J", oxwm.client.move_stack(1))
oxwm.key.bind(shift, "K", oxwm.client.move_stack(-1))
oxwm.key.bind(mod, "H", oxwm.set_master_factor(-5))
oxwm.key.bind(mod, "L", oxwm.set_master_factor(5))
oxwm.key.bind(mod, "I", oxwm.inc_num_master(1))
oxwm.key.bind(shift, "I", oxwm.inc_num_master(-1))
oxwm.key.bind(ctrl, "Period", oxwm.layout.cycle())
oxwm.key.bind(shift, "T", oxwm.layout.set("tiling"))
oxwm.key.bind(shift, "F", oxwm.layout.set("floating"))
oxwm.key.bind(shift, "M", oxwm.layout.set("monocle"))
oxwm.key.bind(shift, "Q", oxwm.quit())
oxwm.key.bind(shift, "R", oxwm.restart())
oxwm.key.bind(mod, "B", oxwm.toggle_bar())
oxwm.key.bind({ "Mod4", "Mod1" }, "0", oxwm.toggle_gaps())

for tag = 1, 7 do
	local key = tostring(tag)
	oxwm.key.bind(mod, key, oxwm.tag.view(tag - 1))
	oxwm.key.bind(shift, key, oxwm.tag.move_to(tag - 1))
	oxwm.key.bind(ctrl, key, oxwm.tag.toggleview(tag - 1))
	oxwm.key.bind(ctrl_shift, key, oxwm.tag.toggletag(tag - 1))
end

oxwm.autostart("gentoo-pipewire-launcher")
oxwm.autostart("xrdb -merge ~/.Xresources")
oxwm.autostart("xset b off")
oxwm.autostart("xset dpms 0 0 900")
oxwm.autostart("xset r rate 250 50")
oxwm.autostart("setxkbmap custom")
oxwm.autostart("/usr/libexec/polkit-gnome-authentication-agent-1")
oxwm.autostart("dunst")
oxwm.autostart("blueman-applet")
oxwm.autostart("playerctld daemon")
oxwm.autostart("udiskie --tray")
oxwm.autostart("gnome-keyring-daemon --start --components=secrets,pkcs11")
oxwm.autostart("xss-lock --transfer-sleep-lock -- lock-session")
oxwm.autostart(
	"xautolock -time 10 -locker lock-session -notify 30 -notifier 'notify-send -t 2000 -a xautolock \"Locking in 30 seconds\"'"
)
oxwm.autostart("openrgb --noautoconnect -p NRGB")
oxwm.autostart("localsend")
oxwm.autostart("/opt/Bitwarden/bitwarden")
oxwm.autostart("CM_SELECTIONS=clipboard clipmenud")
oxwm.autostart("pgrep -x emacs >/dev/null || emacs --daemon")
oxwm.autostart("pgrep -x wezterm-mux-ser >/dev/null || wezterm-mux-server --config-file ~/.config/wezterm/wezterm.lua")
oxwm.autostart('xwallpaper --zoom "$HOME/.local/share/backgrounds/fantasy-woods.jpg"')
