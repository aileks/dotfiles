-- Personal keybinding overrides, merged on top of Omarchy's defaults.
-- View the full binding set: omarchy menu keybindings --print
--
-- hjkl replaces Omarchy's arrow navigation. SUPER+H was unbound; SUPER+J/K/L
-- are freed from their Omarchy defaults first.
hl.unbind("SUPER + J") -- was: toggle window split
hl.unbind("SUPER + K") -- was: keybindings menu (still available via `omarchy menu keybindings`)
hl.unbind("SUPER + L") -- was: toggle workspace layout

for _, arrow in ipairs({ "LEFT", "RIGHT", "UP", "DOWN" }) do
	hl.unbind("SUPER + " .. arrow) -- was: focus window
	hl.unbind("SUPER + SHIFT + " .. arrow) -- was: swap window
	hl.unbind("SUPER + SHIFT + ALT + " .. arrow) -- was: move workspace to monitor
end

-- Exactly eight workspaces: drop Omarchy's 9 and 0 bindings (code:18/19).
for _, code in ipairs({ 18, 19 }) do
	local key = "code:" .. code
	hl.unbind("SUPER + " .. key)
	hl.unbind("SUPER + SHIFT + " .. key)
	hl.unbind("SUPER + SHIFT + ALT + " .. key)
end

-- Close window moves to SUPER+Q so SUPER+W can open the default browser.
hl.unbind("SUPER + W") -- was: close window
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + W", "Browser", { omarchy = "browser" })

local directions = {
	h = "l",
	j = "d",
	k = "u",
	l = "r",
}

for key, direction in pairs(directions) do
	o.bind("SUPER + " .. key, "Focus " .. key, hl.dsp.focus({ direction = direction }))
	o.bind("SUPER + SHIFT + " .. key, "Move window " .. key, hl.dsp.window.move({ direction = direction }))
end
