# Arch Hyprland dotfiles

Personal Arch desktop built around Hyprland with `uwsm`.

![Desktop Showcase](./assets/screenshot.png)

## Install

Preview the commands and compatibility checks without making changes:

```bash
./setup.sh --dry-run
```

Run directly:

```bash
curl -fsSL https://aileks.dev/linux | bash
```

Or clone directly:

```bash
git clone https://github.com/aileks/dotfiles.git ~/.dotfiles
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
| Print / Ctrl + Print / Shift + Print | Region / window / full screenshot      |
| Super + Print / Super + Shift + Print | Region / output recording             |

## tmux

Prefix: `Ctrl + Space`

| Key                 | Action                             |
| ------------------- | ---------------------------------- |
| Prefix + `o`        | Open project session               |
| Prefix + `s`        | Switch session                     |
| Prefix + `w`        | Switch window                      |
| Prefix + `-` / `|`  | Split vertically / horizontally    |
| Prefix + `v`        | Enter copy mode                    |
| Copy mode `v` / `y` | Select / copy to Wayland clipboard |
