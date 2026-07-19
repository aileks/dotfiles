local app = "uwsm app -- "
local local_bin = os.getenv("HOME") .. "/.local/bin/"
local syncobj = " --enable-features=WaylandLinuxDrmSyncobj"
local repeating = { repeating = true }
local media = { locked = true, repeating = true }

local function bind(keys, action, description, flags)
    flags = flags or {}
    flags.description = description
    hl.bind(keys, action, flags)
end

bind("SUPER + Space", hl.dsp.exec_cmd("pkill fuzzel || fuzzel"), "Application launcher")
bind("SUPER + Return", hl.dsp.exec_cmd(app .. "alacritty"), "Terminal")
bind("SUPER + W", hl.dsp.exec_cmd(app .. "helium-browser" .. syncobj), "Browser")
bind("SUPER + E", hl.dsp.exec_cmd(app .. "nautilus --new-window"), "Files")
bind("SUPER + S", hl.dsp.exec_cmd(app .. "signal-desktop" .. syncobj), "Signal")
bind("SUPER + M", hl.dsp.exec_cmd(app .. "fastmail" .. syncobj), "Fastmail")
bind("SUPER + I", hl.dsp.exec_cmd(local_bin .. "desktop-settings"), "Desktop settings")
bind("SUPER + V", hl.dsp.exec_cmd(local_bin .. "clipboard-menu"), "Clipboard history")
bind("SUPER + N", hl.dsp.exec_cmd("swaync-client -t -sw"), "Notification center")
bind("SUPER + SHIFT + slash", hl.dsp.exec_cmd(local_bin .. "keybinds-menu"), "Keybind help")
bind("SUPER + Escape", hl.dsp.exec_cmd("loginctl lock-session"), "Lock session")
bind("SUPER + SHIFT + P", hl.dsp.exec_cmd(local_bin .. "power-menu"), "Power menu")

bind("SUPER + Q", hl.dsp.window.close(), "Close window")
bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen")
bind("SUPER + SHIFT + Space", hl.dsp.window.float(), "Toggle floating")
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

bind("SUPER + CTRL + h", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), "Shrink width", repeating)
bind("SUPER + CTRL + l", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), "Grow width", repeating)
bind("SUPER + CTRL + j", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), "Grow height", repeating)
bind("SUPER + CTRL + k", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), "Shrink height", repeating)

bind("SUPER + mouse:272", hl.dsp.window.drag(), "Move window with mouse", { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), "Resize window with mouse", { mouse = true })

bind("Print", hl.dsp.exec_cmd(local_bin .. "desktop-screenshot region"), "Region screenshot")
bind("SHIFT + Print", hl.dsp.exec_cmd(local_bin .. "desktop-screenshot output"), "Full screenshot")

bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume +5"), "Volume up", media)
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -5"), "Volume down", media)
bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), "Mute audio", media)
bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), "Mute microphone", media)
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Play or pause", media)
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Play or pause", media)
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), "Next track", media)
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), "Previous track", media)
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(local_bin .. "monitor-brightness up"), "Brightness up", media)
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(local_bin .. "monitor-brightness down"), "Brightness down", media)
