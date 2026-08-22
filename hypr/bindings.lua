hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
hl.unbind("SUPER + SHIFT + F")

o.bind("SUPER + E", "File Manager", "nautilus")

for _, arrow in ipairs({ "LEFT", "RIGHT", "UP", "DOWN" }) do
  hl.unbind("SUPER + " .. arrow)
  hl.unbind("SUPER + SHIFT + " .. arrow)
  hl.unbind("SUPER + SHIFT + ALT + " .. arrow)
end

for _, code in ipairs({ 18, 19 }) do
  local key = "code:" .. code
  hl.unbind("SUPER + " .. key)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
end

hl.unbind("SUPER + W")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + W", "Browser", { omarchy = "browser" })

hl.unbind("SUPER + SLASH")
o.bind("SUPER + SLASH", "Keybindings", "omarchy-menu-keybindings")
hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "bitwarden-desktop", focus = "^bitwarden-desktop$" })
hl.unbind("SUPER + ALT + SLASH")

local directions = {
  h = "l",
  j = "d",
  k = "u",
  l = "r",
}

for key, direction in pairs(directions) do
  o.bind("SUPER + " .. key, "Focus " .. key, hl.dsp.focus({ direction = direction }))
  o.bind("SUPER + SHIFT + " .. key, "Swap window " .. key, hl.dsp.window.swap({ direction = direction }))
end
