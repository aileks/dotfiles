local window_ready = os.getenv("HOME") .. "/.local/bin/window-ready"

hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "dialogs-float",
    match = { title = "^(Open File|Save File|Select a File|Choose Files|Authentication Required)$" },
    float = true,
    center = true,
})

for _, class in ipairs({
    "^(blueman-manager)$",
    "^(nm-connection-editor)$",
    "^(nwg-look)$",
    "^(nwg-displays)$",
    "^(org.gnome.DiskUtility)$",
    "^(org.pulseaudio.pavucontrol)$",
}) do
    hl.window_rule({
        name = "settings-float-" .. class,
        match = { class = class },
        float = true,
        center = true,
        size = "70% 70%",
    })
end

hl.window_rule({
    name = "fix-xwayland-drag",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

return hl.on("window.urgent", function(window)
    if window == nil or window.active then
        return
    end

    hl.exec_cmd(window_ready .. " " .. window.address)
end)
