hl.window_rule({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "dialogs-float",
	match = { class = "^(xdg-desktop-portal-gtk)$" },
	float = true,
	center = true,
})

hl.window_rule({
	name = "satty-float",
	match = { class = "^(org.satty.satty)$" },
	float = true,
	center = true,
})

hl.window_rule({
	name = "settings-float",
	match = {
		class = [[^(blueman-manager|nm-connection-editor|org\.gnome\.DiskUtility|org\.pulseaudio\.pavucontrol|qalculate-gtk)$]],
	},
	float = true,
	center = true,
})

hl.window_rule({
	name = "zoom-overlay-stability",
	match = {
		class = "^(zoom)$",
		xwayland = true,
	},
	no_anim = true,
	no_blur = true,
	no_follow_mouse = true,
})

hl.window_rule({
	name = "fix-xwayland-drag",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})
