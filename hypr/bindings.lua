-- hjkl replaces Omarchy's arrow navigation; SUPER+H was already free.
hl.unbind("SUPER + J") -- was: toggle window split
hl.unbind("SUPER + K") -- was: keybindings menu, now on SUPER+SLASH below
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

hl.unbind("SUPER + SLASH") -- was: monitor scaling up
o.bind("SUPER + SLASH", "Keybindings", "omarchy-menu-keybindings")
hl.unbind("SUPER + SHIFT + SLASH") -- was: 1Password
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "bitwarden", focus = "^Bitwarden$" })
hl.unbind("SUPER + ALT + SLASH") -- was: monitor scaling down

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
