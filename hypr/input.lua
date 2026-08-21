-- Personal input overrides. Omarchy defaults apply wherever this is silent.
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")

hl.config({
	input = {
		-- Caps Lock and Ctrl are swapped at the xkb level. Clearing the xkb
		-- rule fields keeps them from overriding the compiled keymap file.
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
