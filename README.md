# Gentoo dotfiles

My Gentoo configs for [MangoWM](https://mangowm.github.io/).

## Install

```sh
git clone --recurse-submodules https://github.com/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

Run from a checkout inside the desktop user's home. The installer requests sudo
for system setup. When running as root, pass `--user USER`. Use `--dry-run` to
inspect planned changes, or `--chroot` when preparing an installation in a chroot.
Missing user tools are installed at the versions pinned in `install.sh`. Pass
`--update-tools` to apply those versions to existing installations. Ordinary
reruns preserve installed user tools and skip unchanged dwl builds and caches.

Select dwl in Ly. The desktop entry runs `/usr/local/bin/start-dwl`, which owns
the D-Bus session, parallel status workers, compositor restart, and cleanup.
`config/dwl/autostart.sh` starts and stops the session's desktop processes.

## Rebuild and restart

Bindings and bar rendering are compiled into dwl. After editing its sources,
rebuild and install from the checkout:

```sh
sudo make -C config/dwl install
```

This requires the build dependencies installed by `install.sh`, including
wlroots 0.19. The standalone Makefile installs the compositor and desktop entry.
Use the root installer for a complete session, including `start-dwl` and user
configuration links.

`Mod + Shift + R` restarts the compositor and its session children. It disconnects
Wayland applications, so save work first. This is required for compiled changes.
Autostart and status configuration changes also take effect on session restart.
Native application configs take effect when their applications reload them.

## Layout

- `bin/`: daily-use commands, linked into `~/.local/bin`
- `config/`: application configs, linked into `~/.config`
- `config/dwl/`: patched compositor sources and compiled `config.def.h`. Only `autostart.sh` and `status.conf` are linked into `~/.config/dwl`
- `config/dwl/patches/`: historical patch provenance, not installer build inputs. The checked-in C sources are authoritative
- `bin/bar-*`: status commands called by `start-dwl` workers, with click actions dispatched by the compositor
- `config/rofi/`: launcher and script menu appearance
- `session/`: session entry points and startup scripts, installed to `/usr/local/bin`
- `etc/`: system files, installed as root-owned copies
- `etc/portage/`: per-package keywords, USE flags, and licenses
- package lists live in the arrays at the top of `install.sh`

MIME defaults live in `config/xdg/mimeapps.list`. The installer merges its managed
defaults into the user's file while preserving other associations. The Qt palette
is installed at `/usr/local/share/qt6ct/colors/cinder-grove.conf` for every user.
Qt settings are installed as a writable copy so preferences-window geometry
does not get written back into the checkout.

`home-backup` keeps 30 completed snapshots and removes logs older than 30 days
after a successful backup. Interrupted snapshots are discarded on the next run.
Rootless container storage, including the disposable pgdev database, is excluded.

## Keybinds

> [!NOTE]  
> `Mod` is the Super key.

### Apps and tools

| Keys                 | Action                 |
| -------------------- | ---------------------- |
| `Mod + Space`        | app launcher (rofi)    |
| `Mod + Return`       | WezTerm mux terminal   |
| `Mod + X`            | Emacsclient            |
| `Mod + W`            | browser                |
| `Mod + E`            | file manager           |
| `Mod + S`            | Signal                 |
| `Mod + A`            | wiremix                |
| `Mod + V`            | clipboard history      |
| `Mod + ;`            | emoji picker           |
| `Mod + O`            | color picker (hyprpicker) |
| `Mod + =`            | Qalculate GTK          |
| `Mod + Shift + P`    | power menu             |

### Capture

| Keys                  | Action                     |
| --------------------- | -------------------------- |
| `Print`               | screenshot region          |
| `Ctrl + Print`        | screenshot focused window  |
| `Shift + Print`       | screenshot full screen     |
| `Mod + Shift + O`     | OCR scan + copy            |
| `Mod + R`             | recording menu             |
| `Mod + Print`         | record screen region       |
| `Mod + Shift + Print` | record the focused monitor |

### Session

| Keys                     | Action                        |
| ------------------------ | ----------------------------- |
| `Mod + Esc`              | lock session                  |
| `Mod + N`                | toggle do not disturb (dunst) |
| `Mod + Ctrl + Shift + N` | notification actions and URLs |
| `Mod + Shift + R`        | reload Mango configuration     |
| `Mod + Shift + Q`        | quit Mango                     |

### Windows

Tags use master-and-stack tiling. Individual windows can still float.

| Keys                                  | Action                                |
| ------------------------------------- | ------------------------------------- |
| `Mod + Q`                             | close window                          |
| `Mod + F`                             | toggle fullscreen                     |
| `Mod + Shift + Space`                 | toggle floating                       |
| `Mod + J` / `Mod + K`                 | focus next or previous window         |
| `Mod + Shift + J` / `Mod + Shift + K` | move window within the stack          |
| `Mod + H` / `Mod + L`                 | shrink or grow the master area        |
| `Mod + I` / `Mod + Shift + I`         | add or remove a master slot           |
| `Mod + Ctrl + Return`                 | swap focused window with master       |
| `Mod + B`                             | toggle Waybar                         |
| `Mod + Left drag`                     | move window                           |
| `Mod + Middle click`                  | toggle floating                       |
| `Mod + Right drag`                    | resize window                         |
| `Mod + Alt + 0`                       | toggle gaps                           |

### Tags and monitors

| Keys                          | Action                          |
| ----------------------------- | ------------------------------- |
| `Mod + 1..7`                  | view tag                        |
| `Mod + Ctrl + 1..7`           | toggle tag visibility           |
| `Mod + Shift + 1..7`          | move window to tag              |
| `Mod + Ctrl + Shift + 1..7`   | toggle window membership of tag |
| `Mod + ,` / `Mod + .`         | focus left or right monitor     |
| `Mod + Shift + ,` / `Mod + Shift + .` | send window to left or right monitor |

### Media and brightness

| Keys                         | Action                                |
| ---------------------------- | ------------------------------------- |
| `Volume Up / Down`           | volume ±5 percentage points, capped at 100% |
| `Volume Mute`                | toggle output mute                    |
| `Microphone Mute`            | toggle microphone mute                |
| `Play / Pause / Next / Prev` | media player control (playerctl)      |
| `Brightness Up / Down`       | external monitor brightness (ddcutil) |

### Status bar

| Control | Action |
| ------- | ------ |
| Tag left-click / right-click | view tag / toggle tag visibility |
| Media left-click / middle-click / right-click | play or pause / previous / next |
| CPU, temperature, or memory click | open btop |
| Network click | open nmtui |
| Volume left-click | open wiremix |
| Volume right-click / middle-click | toggle output mute / microphone mute |
| Volume scroll | adjust volume by 5 percentage points, capped at 100% |
| Clock left-click | switch between 24-hour and 12-hour formats |

### WezTerm

`Leader` is `Ctrl + Space`

Workspace selection is inside WezTerm. `Mod + T` is no longer bound.

| Keys                    | Action                                    |
| ----------------------- | ----------------------------------------- |
| `Leader`, `c`           | new tab                                   |
| `Leader`, `n` / `p`     | next or previous tab                      |
| `Leader`, `Space`       | return to last tab                        |
| `Leader`, `1..9`        | select tab                                |
| `Leader`, `-`           | split into top and bottom panes           |
| `Leader`, `\|`          | split into left and right panes           |
| `Leader`, `v`           | enter copy mode                           |
| `Leader`, `s`           | choose an existing workspace              |
| `Leader`, `w`           | fuzzy tab picker                          |
| `Leader`, `o`           | enter a workspace name to create or switch |
| `Leader`, `^`           | return to previous workspace              |
| `Leader`, `d`           | detach from the current domain            |
| `Alt + h/j/k/l`         | focus left/down/up/right pane             |
| `Alt + Shift + h/j/k/l` | resize pane left/down/up/right by 5 cells |

### Yazi

| Keys            | Action                            |
| --------------- | --------------------------------- |
| `g, b`          | open bookmarks and mounted drives |
| `D` or `Delete` | trash selected files              |
| `e`             | edit selected files in Neovim     |
