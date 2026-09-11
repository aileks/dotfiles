# Gentoo dotfiles

My Gentoo configuration using [MangoWM](https://github.com/mangowm/mango)

## Install

On a booted Gentoo OpenRC system with sudo and networking working:

```sh
git clone --recurse-submodules https://github.com/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Layout

- `bin/`: daily-use commands, linked into `~/.local/bin`
- `config/`: application configs, linked into `~/.config`
- `etc/`, `overlay/`, `mango.desktop`: system files, installed as root-owned copies
- `etc/portage/`: per-package keywords, USE flags, and licenses
- package lists live in the arrays at the top of `install.sh`

## Keybinds

> [!NOTE]  
> `Mod` is the Super key.

### Apps and tools

| Keys                 | Action                 |
| -------------------- | ---------------------- |
| `Mod + Space`        | app launcher (rofi)    |
| `Mod + Ctrl + Space` | desktop actions menu   |
| `Mod + Return`       | WezTerm mux terminal   |
| `Mod + T`            | WezTerm workspace menu |
| `Mod + W`            | browser                |
| `Mod + E`            | file manager           |
| `Mod + S`            | Signal                 |
| `Mod + A`            | wiremix                |
| `Mod + M`            | Fastmail               |
| `Mod + V`            | clipboard history      |
| `Mod + ;`            | emoji picker           |
| `Mod + O`            | color picker           |
| `Mod + =`            | quick calculate        |
| `Mod + Ctrl + R`     | reminders menu         |
| `Mod + Shift + P`    | power menu             |

### Capture

| Keys                  | Action                     |
| --------------------- | -------------------------- |
| `Print`               | screenshot region          |
| `Ctrl + Print`        | screenshot focused window  |
| `Shift + Print`       | screenshot full screen     |
| `Mod + Shift + O`     | OCR scan + copy            |
| `Mod + Ctrl + O`      | QR code scan + copy        |
| `Mod + R`             | recording menu             |
| `Mod + Print`         | record screen region       |
| `Mod + Shift + Print` | record the focused monitor |

### Session

| Keys                     | Action                        |
| ------------------------ | ----------------------------- |
| `Mod + Esc`              | lock session                  |
| `Mod + N`                | toggle do not disturb (dunst) |
| `Mod + Shift + N`        | notification history          |
| `Mod + Ctrl + Shift + N` | notification actions and URLs |
| `Mod + Ctrl + N`         | toggle night light            |
| `Mod + Shift + R`        | reload Mango configuration    |
| `Mod + Shift + Q`        | quit Mango                    |

### Windows

| Keys                                  | Action                                 |
| ------------------------------------- | -------------------------------------- |
| `Mod + Q`                             | close window                           |
| `Mod + F`                             | toggle fullscreen                      |
| `Mod + Shift + Space`                 | toggle floating                        |
| `Mod + J` / `Mod + K`                 | focus next or previous window          |
| `Mod + Shift + J` / `Mod + Shift + K` | exchange with next or previous window  |
| `Mod + Shift + Return`                | move window to master                  |
| `Mod + I` / `Mod + Shift + I`         | add or remove a master slot            |
| `Mod + Ctrl + J` / `Mod + Ctrl + K`   | increase or decrease window height     |
| `Mod + H` / `Mod + L`                 | shrink or grow master horizontally     |
| `Mod + Ctrl + Return`                 | reset focused tiled window proportions |
| `Mod + Backtick`                      | toggle scratchpad                      |
| `Mod + Shift + Backtick`              | minimize window                        |
| `Mod + Ctrl + Backtick`               | restore a minimized window             |
| `Mod + Left drag`                     | move window                            |
| `Mod + Right drag`                    | resize window                          |
| `Mod + Middle click`                  | toggle floating                        |
| `Mod + Scroll up/down`                | focus previous or next window          |

### Tags and monitors

| Keys                                  | Action                               |
| ------------------------------------- | ------------------------------------ |
| `Mod + 1..7`                          | view tag                             |
| `Mod + Ctrl + 1..7`                   | toggle tag visibility                |
| `Mod + Shift + 1..7`                  | move window to tag                   |
| `Mod + Ctrl + Shift + 1..7`           | toggle window membership of tag      |
| `Mod + Tab`                           | return to previous tag view          |
| `Mod + ,` / `Mod + .`                 | focus left or right monitor          |
| `Mod + Shift + ,` / `Mod + Shift + .` | send window to left or right monitor |
| `Mod + Ctrl + M`                      | monitor menu                         |

### Media and brightness

| Keys                         | Action                                |
| ---------------------------- | ------------------------------------- |
| `Volume Up / Down / Mute`    | output volume                         |
| `Mic Mute`                   | microphone mute                       |
| `Play / Pause / Next / Prev` | media player control (playerctl)      |
| `Brightness Up / Down`       | external monitor brightness (ddcutil) |

### WezTerm

`Leader` is `Ctrl + Space`

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
| `Leader`, `o`           | project/workspace menu                    |
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
