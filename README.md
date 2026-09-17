# dotfiles

My Gentoo configs for [OXWM](https://github.com/tonybanters/oxwm) on X11.

## Install

```sh
git clone --recurse-submodules https://github.com/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Keybinds

> [!NOTE]  
> `Mod` is the Super key.

### Apps and tools

| Keys              | Action                     |
| ----------------- | -------------------------- |
| `Mod + Space`     | app launcher (rofi)        |
| `Mod + Return`    | terminal                   |
| `Mod + X`         | Emacsclient                |
| `Mod + W`         | browser                    |
| `Mod + E`         | file manager               |
| `Mod + S`         | Signal                     |
| `Mod + A`         | wiremix                    |
| `Mod + V`         | clipboard history          |
| `Mod + ;`         | emoji picker               |
| `Mod + =`         | Qalculate GTK              |
| `Mod + Shift + P` | power menu                 |

### Capture

| Keys                  | Action                    |
| --------------------- | ------------------------- |
| `Print`               | screenshot region         |
| `Ctrl + Print`        | screenshot focused window |
| `Shift + Print`       | screenshot full screen    |
| `Mod + O`             | OCR scan + copy           |
| `Mod + R`             | recording menu            |
| `Mod + Ctrl + R`      | stop recording            |
| `Mod + Print`         | record screen region      |
| `Mod + Shift + Print` | record the screen         |

### Session

| Keys                     | Action                        |
| ------------------------ | ----------------------------- |
| `Mod + Esc`              | lock session                  |
| `Mod + N`                | toggle do not disturb (dunst) |
| `Mod + Ctrl + Shift + N` | notification actions and URLs |
| `Mod + Shift + R`        | reload OXWM configuration     |
| `Mod + Shift + Q`        | quit OXWM                     |

### Windows

Tags use master-and-stack tiling. Individual windows can still float.

| Keys                                  | Action                                 |
| ------------------------------------- | -------------------------------------- |
| `Mod + Q`                             | close window                           |
| `Mod + F`                             | toggle fullscreen                      |
| `Mod + Shift + Space`                 | toggle floating                        |
| `Mod + J` / `Mod + K`                 | focus next or previous window          |
| `Mod + Shift + J` / `Mod + Shift + K` | move window within the stack           |
| `Mod + H` / `Mod + L`                 | shrink or grow the master area         |
| `Mod + I` / `Mod + Shift + I`         | add or remove a master slot            |
| `Mod + B`                             | toggle the bar                         |
| `Mod + Left drag`                     | move window                            |
| `Mod + Middle click`                  | toggle floating                        |
| `Mod + Right drag`                    | resize window                          |
| `Mod + Alt + 0`                       | toggle gaps                            |
| `Mod + Ctrl + .`                      | cycle layouts                          |
| `Mod + Shift + T / F / M`             | set tiling / floating / monocle layout |

### Tags

| Keys                        | Action                          |
| --------------------------- | ------------------------------- |
| `Mod + 1..7`                | view tag                        |
| `Mod + Ctrl + 1..7`         | toggle tag visibility           |
| `Mod + Shift + 1..7`        | move window to tag              |
| `Mod + Ctrl + Shift + 1..7` | toggle window membership of tag |
