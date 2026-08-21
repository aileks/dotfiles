-- hj/l replace Omarchy's arrow navigation; SUPER+K stays on Omarchy's
-- keybindings menu, so focus-up has no SUPER modifier.
hl.unbind("SUPER + J") -- was: toggle window split
hl.unbind("SUPER + L") -- was: toggle workspace layout

-- was: focus / swap window / move workspace to monitor
for _, arrow in ipairs({ "LEFT", "RIGHT", "UP", "DOWN" }) do
	hl.unbind("SUPER + " .. arrow)
	hl.unbind("SUPER + SHIFT + " .. arrow)
	hl.unbind("SUPER + SHIFT + ALT + " .. arrow)
end

-- code:18/19 are the 9 and 0 keys; exactly eight workspaces.
for _, code in ipairs({ 18, 19 }) do
	local key = "code:" .. code
	hl.unbind("SUPER + " .. key)
	hl.unbind("SUPER + SHIFT + " .. key)
	hl.unbind("SUPER + SHIFT + ALT + " .. key)
end

hl.unbind("SUPER + W") -- was: close window
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + W", "Browser", { omarchy = "browser" })

local directions = {
	h = "l",
	j = "d",
	l = "r",
}

for key, direction in pairs(directions) do
	o.bind("SUPER + " .. key, "Focus " .. key, hl.dsp.focus({ direction = direction }))
	o.bind("SUPER + SHIFT + " .. key, "Move window " .. key, hl.dsp.window.move({ direction = direction }))
end
