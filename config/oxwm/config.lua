local colors = {
    background = '#131210',
    text = '#BBB3A9',
    bright = '#DDD5CA',
    muted = '#58534C',
    orange = '#E17A3F',
    red = '#B34A45',
    green = '#879B5C',
    blue = '#6785A1',
    purple = '#9A788F',
    cyan = '#58918C',
}

local mod = { 'Mod4' }
local shift = { 'Mod4', 'Shift' }
local ctrl = { 'Mod4', 'Control' }
local ctrl_shift = { 'Mod4', 'Control', 'Shift' }

oxwm.set_terminal('wezterm')
oxwm.set_modkey('Mod4')
oxwm.set_tags({ '1', '2', '3', '4', '5', '6', '7' })
oxwm.set_layout('tiling')
oxwm.border.set_width(2)
oxwm.border.set_focused_color(colors.orange)
oxwm.border.set_unfocused_color(colors.muted)
oxwm.gaps.set_enabled(true)
oxwm.gaps.set_smart(false)
oxwm.gaps.set_inner(4, 4)
oxwm.gaps.set_outer(4, 4)

oxwm.bar.set_font('Iosevka Nerd Font Propo:size=11')
oxwm.bar.set_position('top')
oxwm.bar.set_scheme_normal(colors.text, colors.background, colors.muted)
oxwm.bar.set_scheme_occupied(colors.bright, colors.background, colors.orange)
oxwm.bar.set_scheme_selected(colors.orange, colors.background, colors.orange)
oxwm.bar.set_scheme_urgent(colors.bright, colors.red, colors.red)

local status_blocks = {
    { 'bar-dnd', 1, colors.orange, 'notification-history' },
    { 'bar-network', 5, colors.cyan, 'wezterm start --always-new-process -- nmtui' },
    { 'bar-volume', 1, colors.purple, 'audio sink mute' },
    { 'bar-cpu-temperature', 10, colors.blue, 'wezterm start --always-new-process -- btop' },
    { 'bar-memory', 10, colors.green, 'wezterm start --always-new-process -- btop' },
    { 'bar-gpu', 5, colors.purple, 'wezterm start --always-new-process -- nvtop' },
    { 'bar-clock', 1, colors.bright, 'env BLOCK_BUTTON=1 bar-clock' },
}

local blocks = { oxwm.bar.block.systray({}) }
for index, block in ipairs(status_blocks) do
    if index > 1 then
        blocks[#blocks + 1] = oxwm.bar.block.static({ text = '│', color = colors.muted })
    end
    blocks[#blocks + 1] = oxwm.bar.block.shell({
        command = block[1],
        format = '{}',
        interval = block[2],
        color = block[3],
        click = block[4],
        underline = false,
    })
end
oxwm.bar.set_blocks(blocks)

for _, class in ipairs({
    'imv', 'Qalculate-gtk', 'Blueman', 'blueman', 'Bitwarden', 'bitwarden',
    'LocalSend', 'localsend', 'localSend', 'Localsend',
    'polkit-gnome', 'Polkit-gnome', 'xdg-desktop-portal-gtk',
    'nm-connection-editor', 'Nm-connection-editor',
}) do
    oxwm.rule.add({ class = class, floating = true })
end

local launchers = {
    { mod, 'Return', 'wezterm connect unix' },
    { mod, 'Space', 'rofi -show drun' },
    { mod, 'X', "emacsclient -c -a ''" },
    { mod, 'T', 'wezterm-sessions' },
    { mod, 'W', 'zen-browser' },
    { mod, 'E', 'wezterm start --always-new-process -- yazi' },
    { mod, 'S', 'signal-desktop' },
    { mod, 'A', 'wezterm start --always-new-process -- wiremix' },
    { mod, 'O', 'color-picker' },
    { mod, 'V', 'clipboard-menu' },
    { mod, 'semicolon', 'bemoji -n' },
    { mod, 'Escape', 'lock-session' },
    { mod, 'N', 'dnd-toggle' },
    { ctrl, 'N', 'night-light' },
    { shift, 'P', 'power-menu' },
    { mod, 'R', 'screenrecord menu' },
    { {}, 'Print', 'screenshot region' },
    { { 'Control' }, 'Print', 'screenshot window' },
    { { 'Shift' }, 'Print', 'screenshot full' },
    { mod, 'Print', 'screenrecord region' },
    { shift, 'Print', 'screenrecord output' },
    { ctrl, 'Space', 'desktop-actions' },
    { shift, 'O', 'region-ocr' },
    { ctrl, 'O', 'qr-scan' },
    { ctrl, 'R', 'reminder' },
    { mod, 'Equal', 'calculate' },
    { shift, 'N', 'notification-history' },
    { ctrl_shift, 'N', 'dunstctl context' },
    { {}, 'XF86AudioPlay', 'playerctl play-pause' },
    { {}, 'XF86AudioPause', 'playerctl play-pause' },
    { {}, 'XF86AudioNext', 'playerctl next' },
    { {}, 'XF86AudioPrev', 'playerctl previous' },
    { {}, 'XF86AudioRaiseVolume', 'audio sink up' },
    { {}, 'XF86AudioLowerVolume', 'audio sink down' },
    { {}, 'XF86AudioMute', 'audio sink mute' },
    { {}, 'XF86MonBrightnessUp', 'brightness up' },
    { {}, 'XF86MonBrightnessDown', 'brightness down' },
}

for _, binding in ipairs(launchers) do
    oxwm.key.bind(binding[1], binding[2], oxwm.spawn(binding[3]))
end

oxwm.key.bind(mod, 'Q', oxwm.client.kill())
oxwm.key.bind(mod, 'F', oxwm.client.toggle_fullscreen())
oxwm.key.bind(shift, 'Space', oxwm.client.toggle_floating())
oxwm.key.bind(mod, 'J', oxwm.client.focus_stack(1))
oxwm.key.bind(mod, 'K', oxwm.client.focus_stack(-1))
oxwm.key.bind(shift, 'J', oxwm.client.move_stack(1))
oxwm.key.bind(shift, 'K', oxwm.client.move_stack(-1))
oxwm.key.bind(mod, 'H', oxwm.set_master_factor(-50))
oxwm.key.bind(mod, 'L', oxwm.set_master_factor(50))
oxwm.key.bind(mod, 'I', oxwm.inc_num_master(1))
oxwm.key.bind(shift, 'I', oxwm.inc_num_master(-1))
oxwm.key.bind(mod, 'Comma', oxwm.monitor.focus(-1))
oxwm.key.bind(mod, 'Period', oxwm.monitor.focus(1))
oxwm.key.bind(shift, 'Comma', oxwm.monitor.tag(-1))
oxwm.key.bind(shift, 'Period', oxwm.monitor.tag(1))
oxwm.key.bind(shift, 'Q', oxwm.quit())
oxwm.key.bind(shift, 'R', oxwm.restart())
oxwm.key.bind(mod, 'B', oxwm.toggle_bar())
oxwm.key.bind(shift, 'T', oxwm.layout.set('tiling'))
oxwm.key.bind(shift, 'F', oxwm.layout.set('floating'))
oxwm.key.bind(shift, 'M', oxwm.layout.set('monocle'))
oxwm.key.bind(ctrl, 'Period', oxwm.layout.cycle())
oxwm.key.bind({ 'Mod4', 'Mod1' }, '0', oxwm.toggle_gaps())

for tag = 1, 7 do
    local key = tostring(tag)
    oxwm.key.bind(mod, key, oxwm.tag.view(tag - 1))
    oxwm.key.bind(shift, key, oxwm.tag.move_to(tag - 1))
    oxwm.key.bind(ctrl, key, oxwm.tag.toggleview(tag - 1))
    oxwm.key.bind(ctrl_shift, key, oxwm.tag.toggletag(tag - 1))
end

oxwm.autostart('bash "${XDG_CONFIG_HOME:-$HOME/.config}/oxwm/autostart.sh"')
