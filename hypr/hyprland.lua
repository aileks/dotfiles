hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)

hl.monitor({ output = "", mode = "highrr", position = "auto", scale = 1 })

for workspace = 1, 8 do
    hl.workspace_rule({
        workspace = tostring(workspace),
        persistent = true,
        default = workspace == 1,
    })
end

local state = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/dotfiles"
pcall(dofile, state .. "/monitors.lua")
pcall(dofile, state .. "/workspaces.lua")

require("settings")
require("bindings")
require("rules")
