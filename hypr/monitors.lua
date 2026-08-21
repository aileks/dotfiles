local omarchy_gdk_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

hl.monitor({ output = "DP-1", mode = "2560x1440@200", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@200", position = "auto-left", scale = 1, transform = 1 })

for workspace = 1, 7 do
  hl.workspace_rule({
    workspace = tostring(workspace),
    monitor = "DP-1",
    default = workspace == 1,
    persistent = true,
  })
end

hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-1", default = true, persistent = true })
