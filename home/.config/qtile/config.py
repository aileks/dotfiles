from pathlib import Path

from dictation import held_dictation
from libqtile import bar, hook, layout, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy

mod = "mod4"
background = "#140E0A"
foreground = "#DED6D0"
muted = "#80756E"
accent = "#B39887"
selection = "#725F52"

groups = [Group(str(number), layout="bsp") for number in range(1, 8)]
layout_settings = {
    "border_width": 2,
    "border_focus": accent,
    "border_normal": muted,
    "margin": 6,
}
layouts = [
    layout.Bsp(**layout_settings, margin_on_single=0, border_on_single=True),
    layout.MonadTall(**layout_settings, ratio=0.5, single_margin=0),
    layout.Max(**layout_settings),
]

keys = [
    Key([mod], "Return", lazy.spawn("alacritty")),
    Key([mod], "space", lazy.spawn("rofi -show drun")),
    Key([mod], "x", lazy.spawn("emacsclient -c -a ''")),
    Key([mod], "w", lazy.spawn("firefox")),
    Key([mod], "s", lazy.spawn("signal-desktop")),
    Key([mod], "e", lazy.spawn("alacritty -e open-nnn")),
    Key([mod], "a", lazy.spawn("alacritty -e wiremix")),
    Key([], "F9", lazy.function(held_dictation.start)),
    Key([mod, "shift"], "d", lazy.spawn("voxtype record cancel")),
    Key([mod], "o", lazy.spawn("region-ocr")),
    Key([mod], "semicolon", lazy.spawn("bemoji -n")),
    Key([mod], "equal", lazy.spawn("qalculate-gtk")),
    Key([mod], "Escape", lazy.spawn("lock-session")),
    Key([mod], "n", lazy.spawn("dnd-toggle")),
    Key([mod, "control", "shift"], "n", lazy.spawn("dunstctl context")),
    Key([mod, "shift"], "p", lazy.spawn("power-menu")),
    Key([mod], "r", lazy.spawn("screenrecord menu")),
    Key([mod, "control"], "r", lazy.spawn("screenrecord stop")),
    Key([mod], "Print", lazy.spawn("screenrecord region")),
    Key([mod, "shift"], "Print", lazy.spawn("screenrecord output")),
    Key([], "Print", lazy.spawn("screenshot region")),
    Key(["control"], "Print", lazy.spawn("screenshot window")),
    Key(["shift"], "Print", lazy.spawn("screenshot full")),
    Key([mod], "b", lazy.hide_show_bar("top")),
    Key([mod], "q", lazy.window.kill()),
    Key([mod, "shift"], "q", lazy.shutdown()),
    Key([mod, "shift"], "r", lazy.restart()),
    Key([mod, "control", "shift"], "r", lazy.reload_config()),
    Key([mod], "f", lazy.window.toggle_fullscreen()),
    Key([mod, "shift"], "space", lazy.window.toggle_floating()),
    Key([mod, "shift"], "f", lazy.window.toggle_floating()),
    Key([mod, "shift"], "b", lazy.group.setlayout("bsp")),
    Key([mod, "shift"], "t", lazy.group.setlayout("monadtall")),
    Key([mod, "shift"], "m", lazy.group.setlayout("max")),
    Key([mod, "control"], "period", lazy.next_layout()),
    Key([mod], "Tab", lazy.next_layout()),
]

for key, direction, tall_resize in (
    ("h", "left", lazy.layout.shrink_main()),
    ("j", "down", lazy.layout.grow()),
    ("k", "up", lazy.layout.shrink()),
    ("l", "right", lazy.layout.grow_main()),
):
    keys.extend(
        [
            Key(
                [mod],
                key,
                getattr(lazy.layout, direction)().when(layout="bsp"),
                getattr(lazy.layout, direction)().when(layout="monadtall"),
                (lazy.layout.previous() if key in "hk" else lazy.layout.next()).when(
                    layout="max"
                ),
            ),
            Key(
                [mod, "shift"],
                key,
                getattr(lazy.layout, f"shuffle_{direction}")().when(layout="bsp"),
                getattr(lazy.layout, f"shuffle_{direction}")().when(layout="monadtall"),
            ),
            Key(
                [mod, "control"],
                key,
                getattr(lazy.layout, f"grow_{direction}")().when(layout="bsp"),
                tall_resize.when(layout="monadtall"),
            ),
        ]
    )

for group in groups:
    keys.extend(
        [
            Key([mod], group.name, lazy.group[group.name].toscreen()),
            Key([mod, "shift"], group.name, lazy.window.togroup(group.name)),
        ]
    )

for key, command in (
    ("XF86AudioPlay", "playerctl play-pause"),
    ("XF86AudioPause", "playerctl play-pause"),
    ("XF86AudioNext", "playerctl next"),
    ("XF86AudioPrev", "playerctl previous"),
    ("XF86AudioRaiseVolume", "audio sink up"),
    ("XF86AudioLowerVolume", "audio sink down"),
    ("XF86AudioMute", "audio sink mute"),
    ("XF86AudioMicMute", "audio source mute"),
    ("XF86MonBrightnessUp", "brightness up"),
    ("XF86MonBrightnessDown", "brightness down"),
):
    keys.append(Key([], key, lazy.spawn(command)))

mouse = [
    Drag(
        [mod],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()
    ),
    Click([mod], "Button2", lazy.window.toggle_floating()),
]

floating_layout = layout.Floating(
    border_width=2,
    border_focus=accent,
    border_normal=muted,
    float_rules=[
        *layout.Floating.default_float_rules,
        *(Match(wm_type=kind) for kind in ("dialog", "utility", "toolbar", "splash")),
        *(
            Match(wm_class=application)
            for application in (
                "imv",
                "Qalculate-gtk",
                "Blueman",
                "Bitwarden",
                "bitwarden",
                "localsend",
                "polkit-gnome",
                "xdg-desktop-portal-gtk",
                "Nm-connection-editor",
            )
        ),
        Match(wm_class="firefox", wm_instance_class="Places"),
    ],
)

widget_defaults = {
    "font": "Iosevka Nerd Font Propo Medium",
    "fontsize": 13,
    "padding": 5,
    "foreground": foreground,
    "background": background,
}

status_widgets = []
for command, interval, color in (
    ("bar-dnd", 1, accent),
    ("bar-volume", 1, "#C6BBB5"),
    ("bar-cpu-temperature", 5, "#A2968E"),
    ("bar-memory", 5, "#A2968E"),
    ("bar-gpu", 5, "#A69082"),
    ("bar-network", 5, "#C1AD9F"),
    ("bar-clock", 1, foreground),
):
    if status_widgets:
        status_widgets.append(widget.TextBox("│", foreground=muted))
    status_widgets.append(
        widget.GenPollCommand(
            cmd=[command], update_interval=interval, foreground=color, markup=False
        )
    )

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    active="#C6BBB5",
                    inactive=muted,
                    this_current_screen_border=selection,
                    this_screen_border=selection,
                    urgent_border="#E07972",
                    highlight_method="block",
                    disable_drag=True,
                ),
                widget.CurrentLayout(),
                widget.WindowName(markup=False),
                *status_widgets,
                widget.Systray(icon_size=20, padding=5),
            ],
            28,
            background=background,
        )
    )
]

auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
wmname = "LG3D"


@hook.subscribe.startup_once
def start_session():
    from libqtile import qtile

    qtile.spawn(["bash", str(Path(__file__).parent / "autostart.sh")])


hook.subscribe.restart(held_dictation.cancel)
hook.subscribe.shutdown(held_dictation.cancel)
