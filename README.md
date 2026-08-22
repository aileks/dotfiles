# Omarchy dotfiles

Personal override layer on top of [Omarchy](https://omarchy.org/).

## Layout

| Repo path                         | Live location                           |
| --------------------------------- | --------------------------------------- |
| `hypr/`                           | `~/.config/hypr`                        |
| `omarchy/shell.toml`              | `~/.config/omarchy/shell.toml`          |
| `omarchy/shell.json`              | `~/.config/omarchy/shell.json`          |
| `omarchy/themes/cinder-grove/`    | `~/.config/omarchy/themes/cinder-grove` |
| `alacritty/`, `nvim/`, `tmux/`, … | `~/.config/...`                         |
| `uwsm/`                           | `~/.config/uwsm`                        |
| `bin/doctor`                      | `~/.local/bin/doctor`                   |
| `setup.sh`                        | Omarchy post-install                    |

## Overrides

> [!NOTE]  
> Some things get clobbered when Omarchy updates occur.

- DP-1 primary, HDMI-A-1 portrait left; eight persistent workspaces (1–7 on
  DP-1, 8 on HDMI-A-1).
- Bar font pinned to 14 (`shell.toml` plus a post-boot hook).
- Caps Lock and Ctrl swapped (`hypr/keymap.xkb`).

| Key                             | Action                   |
| ------------------------------- | ------------------------ |
| Super + `h`/`j`/`k`/`l`         | Focus window             |
| Super + Shift + `h`/`j`/`k`/`l` | Swap window              |
| Super + `q`                     | Close window             |
| Super + `w`                     | Default browser          |
| Super + `/`                     | Keybind help             |
| Super + Shift + `/`             | Bitwarden                |
| Super + 1-8                     | Select workspace         |
| Super + Shift + 1-8             | Move window to workspace |

## Install

```bash
git clone https://github.com/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./setup.sh
```
