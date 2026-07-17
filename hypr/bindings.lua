local app = "uwsm app -- "
local repeating = { repeating = true }
local media = { locked = true, repeating = true }

local function bind(keys, action, description, flags)
    flags = flags or {}
    flags.description = description
    hl.bind(keys, action, flags)
end

bind("SUPER + Space", hl.dsp.exec_cmd("pkill fuzzel || fuzzel"), "Application launcher")
bind("SUPER + Return", hl.dsp.exec_cmd(app .. "alacritty"), "Terminal")
bind("SUPER + W", hl.dsp.exec_cmd(app .. "helium-browser"), "Browser")
bind("SUPER + E", hl.dsp.exec_cmd(app .. "nautilus --new-window"), "Files")
bind("SUPER + S", hl.dsp.exec_cmd(app .. "signal-desktop"), "Signal")
bind("SUPER + M", hl.dsp.exec_cmd(app .. "fastmail"), "Fastmail")
bind("SUPER + I", hl.dsp.exec_cmd("desktop-settings"), "Desktop settings")
bind("SUPER + V", hl.dsp.exec_cmd("clipboard-menu"), "Clipboard history")
bind("SUPER + N", hl.dsp.exec_cmd("swaync-client -t -sw"), "Notification center")
bind("SUPER + slash", hl.dsp.exec_cmd("keybinds-menu"), "Keybind help")
bind("SUPER + Escape", hl.dsp.exec_cmd("loginctl lock-session"), "Lock session")
bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("powermenu"), "Power menu")

bind("SUPER + Q", hl.dsp.window.close(), "Close window")
bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen")
bind("SUPER + apostrophe", hl.dsp.window.float(), "Toggle floating")
bind("SUPER + P", hl.dsp.window.pseudo(), "Toggle pseudotile")
bind("SUPER + X", hl.dsp.layout("togglesplit"), "Toggle split direction")

local directions = {
    h = "left",
    j = "down",
    k = "up",
    l = "right",
}

for key, direction in pairs(directions) do
    bind("SUPER + " .. key, hl.dsp.focus({ direction = direction }), "Focus " .. direction)
    bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }), "Move window " .. direction)
end

for workspace = 1, 8 do
    bind("SUPER + " .. workspace, hl.dsp.focus({ workspace = workspace }), "Workspace " .. workspace)
    bind(
        "SUPER + SHIFT + " .. workspace,
        hl.dsp.window.move({ workspace = workspace, follow = false }),
        "Move window to workspace " .. workspace
    )
end

bind("SUPER + comma", hl.dsp.focus({ monitor = "-1" }), "Previous monitor")
bind("SUPER + period", hl.dsp.focus({ monitor = "+1" }), "Next monitor")
bind("SUPER + SHIFT + comma", hl.dsp.window.move({ monitor = "-1", follow = true }), "Move to previous monitor")
bind("SUPER + SHIFT + period", hl.dsp.window.move({ monitor = "+1", follow = true }), "Move to next monitor")

bind("SUPER + R", hl.dsp.submap("resize"), "Resize mode")
hl.define_submap("resize", function()
    bind("h", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), "Shrink width", repeating)
    bind("l", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), "Grow width", repeating)
    bind("j", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), "Grow height", repeating)
    bind("k", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), "Shrink height", repeating)
    bind("Escape", hl.dsp.submap("reset"), "Exit resize mode")
    bind("Return", hl.dsp.submap("reset"), "Exit resize mode")
end)

bind("SUPER + mouse:272", hl.dsp.window.drag(), "Move window with mouse", { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), "Resize window with mouse", { mouse = true })

bind("Print", hl.dsp.exec_cmd("desktop-screenshot region"), "Region screenshot")
bind("SHIFT + Print", hl.dsp.exec_cmd("desktop-screenshot output"), "Full screenshot")

bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up", media)
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), "Volume down", media)
bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), "Mute audio", media)
bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), "Mute microphone", media)
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Play or pause", media)
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Play or pause", media)
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), "Next track", media)
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), "Previous track", media)
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("monitor-brightness up"), "Brightness up", media)
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("monitor-brightness down"), "Brightness down", media)
