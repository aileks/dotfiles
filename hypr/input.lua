local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")

hl.config({
	input = {
		-- The xkb rule fields must be cleared or they override the compiled
		-- keymap file (caps/ctrl swap).
		kb_file = config_home .. "/hypr/keymap.xkb",
		kb_layout = "",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",
		numlock_by_default = true,
		repeat_rate = 50,
		repeat_delay = 250,
		follow_mouse = 1,
		accel_profile = "flat",
		sensitivity = 0,
	},
})
