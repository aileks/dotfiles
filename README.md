# Arch Hyprland dotfiles

Opinionated Arch desktop built around Hyprland with UWSM.

![Desktop Showcase](./assets/screenshot.png)

## Install

```bash
curl -fsSL https://aileks.dev/linux | bash
```

Or clone directly:

```bash
git clone https://codeberg.org/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

## Keybinds

| Key                             | Action                                      |
| ------------------------------- | ------------------------------------------- |
| Super + Space                   | Launcher                                    |
| Super + Return                  | Alacritty                                   |
| Super + `w`                     | Web Browser                                 |
| Super + `e`                     | File Manager                                |
| Super + `m`                     | Mail application                            |
| Super + `s`                     | Signal Desktop                              |
| Super + `i`                     | Desktop settings menu, including `nwg-look` |
| Super + `q`                     | Close                                       |
| Super + `f`                     | Fullscreen                                  |
| Super + Shift + Space           | Float                                       |
| Super + `h`/`j`/`k`/`l`         | Focus window                                |
| Super + Shift + `h`/`j`/`k`/`l` | Move window                                 |
| Super + Ctrl + `h`/`j`/`k`/`l`  | Resize window                               |
| Super + 1-8                     | Select workspace                            |
| Super + Shift + 1-8             | Move window to workspace                    |
| Super + `,` / `.`               | Select monitor                              |
| Super + Shift + `,` / `.`       | Move window to monitor                      |
| Super + `v`                     | Clipboard history                           |
| Super + `n`                     | Notification center                         |
| Super + Shift + `/`             | Keybind help                                |
| Super + Escape                  | Lock                                        |
| Super + Shift + `p`             | Power menu                                  |
| Print / Shift + Print           | Region / full screenshot                    |

## tmux

Prefix: `Ctrl + Space`

| Key                 | Action                             |
| ------------------- | ---------------------------------- |
| Prefix + `o`        | Open project session               |
| Prefix + `s`        | Switch session                     |
| Prefix + `w`        | Switch window                      |
| Prefix + `-` / `\|` | Split vertically / horizontally    |
| Prefix + `v`        | Enter copy mode                    |
| Copy mode `v` / `y` | Select / copy to Wayland clipboard |
