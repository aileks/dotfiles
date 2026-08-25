# Arch Hyprland dotfiles

Personal Arch desktop built around Hyprland, `uwsm`, and [Mitishell](https://github.com/aileks/mitishell)

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

| Key                                   | Action                            |
| ------------------------------------- | --------------------------------- |
| Super + Space                         | Launcher                          |
| Super + Return                        | Alacritty                         |
| Super + `w`                           | Web Browser                       |
| Super + `e`                           | File Manager                      |
| Super + `m`                           | Mail application                  |
| Super + `i`                           | Mitishell settings                |
| Super + `a`                           | Desktop actions                   |
| Super + `q`                           | Close                             |
| Super + `f`                           | Fullscreen                        |
| Super + Shift + Space                 | Float                             |
| Super + `x`                           | Toggle split direction            |
| Super + `h`/`j`/`k`/`l`               | Focus window                      |
| Super + Shift + `h`/`j`/`k`/`l`       | Move window                       |
| Super + Ctrl + `h`/`j`/`k`/`l`        | Resize window                     |
| Super + 1-8                           | Select workspace                  |
| Super + Shift + 1-8                   | Move window to workspace          |
| Super + `,` / `.`                     | Select monitor                    |
| Super + Shift + `,` / `.`             | Move window to monitor            |
| Super + `v`                           | Clipboard history                 |
| Super + `n`                           | Toggle Do Not Disturb             |
| Super + Ctrl + `n`                    | Toggle Night Light                |
| Super + Ctrl + `r`                    | Open reminders                    |
| Super + Escape                        | Lock                              |
| Super + Shift + `p`                   | Power menu                        |
| Print / Ctrl + Print / Shift + Print  | Region / window / full screenshot |
| Super + Ctrl + Print                  | Extract text from a region        |
| Super + Print / Super + Shift + Print | Region / output recording         |
