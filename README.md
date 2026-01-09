# Arch Linux Dotfiles

Desktop environment built on DWM-Flexipatch with the [Ashen](https://codeberg.org/ficd/ashen) colorscheme.

## Features

- **WM**: DWM w/ Flexipatch
- **Status bar**: dwmblocks with colored status2d modules
- **Terminal**: WezTerm
- **Launcher**: Rofi
- **Compositor**: Picom
- **Notifications**: Dunst
- **Lockscreen**: Betterlockscreen
- **Shell**: Zsh
- **Editor**: Neovim
- **File manager**: Yazi
- **PDF viewer**: Zathura
- **Hyperkey**: Caps Lock → Ctrl+Alt+Super (via keyd)

## Requirements

- Arch Linux (or Arch-based distro)
- Display manager: [ly](https://github.com/fairyglade/ly)
- 4K monitor recommended (tweak DPI otherwise)

### Dependencies

```bash
sudo pacman -S base-devel git xorg xorg-xinit picom dunst rofi feh \
    pamixer playerctl maim xclip xdotool networkmanager wezterm \
    zathura zathura-pdf-mupdf ly

paru -S betterlockscreen ttf-adwaita-mono-nerd keyd
```

## Quick Start

```bash
curl -fsSL https://aileks.dev/linux | bash
```

Or manually:

```bash
git clone --recursive https://github.com/aileks/arch-config.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Usage

```bash
./install.sh              # Interactive menu
./install.sh 1            # Full setup (symlinks + build)
./install.sh 2            # Symlink only
./install.sh --dry-run 1  # Preview changes
```

### Lock on Suspend

```bash
sudo systemctl enable betterlockscreen@$USER
```

## Keybinds

The hyperkey (Caps Lock) maps to Ctrl+Alt+Super. Tap Caps Lock for Escape.

| Key | Action |
|-----|--------|
| **General** ||
| `Hyper` + `Return` | Terminal (WezTerm) |
| `Hyper` + `d` | App launcher (Rofi) |
| `Hyper` + `Ctrl` + `Space` | Emoji picker |
| `Hyper` + `e` | File manager (PCManFM) |
| `Hyper` + `Ctrl` + `l` | Lock screen |
| `Hyper` + `b` | Toggle bar |
| `Hyper` + `q` | Kill window |
| `Hyper` + `Shift` + `q` | Quit DWM |
| `Hyper` + `Shift` + `r` | Restart DWM |
| **Navigation** ||
| `Hyper` + `j` | Focus next |
| `Hyper` + `k` | Focus prev |
| `Hyper` + `h` | Shrink master |
| `Hyper` + `l` | Expand master |
| `Hyper` + `Shift` + `j` | Move down in stack |
| `Hyper` + `Shift` + `k` | Move up in stack |
| `Hyper` + `Shift` + `Return` | Zoom (swap with master) |
| `Hyper` + `Tab` | Toggle last tag |
| `Hyper` + `i` | Increase masters |
| `Hyper` + `Shift` + `i` | Decrease masters |
| **Tags** ||
| `Hyper` + `1-9` | View tag |
| `Hyper` + `Shift` + `1-9` | Move window to tag |
| `Hyper` + `Ctrl` + `1-9` | Toggle tag view |
| `Hyper` + `Ctrl` + `Shift` + `1-9` | Toggle window tag |
| `Hyper` + `0` | View all tags |
| `Hyper` + `Shift` + `0` | Tag window on all |
| **Monitors** ||
| `Hyper` + `,` | Focus prev monitor |
| `Hyper` + `.` | Focus next monitor |
| `Hyper` + `Shift` + `,` | Send to prev monitor |
| `Hyper` + `Shift` + `.` | Send to next monitor |
| **Layouts** ||
| `Hyper` + `t` | Tiled |
| `Hyper` + `f` | Floating |
| `Hyper` + `m` | Monocle |
| `Hyper` + `Space` | Toggle layout |
| `Hyper` + `Shift` + `Space` | Toggle floating |
| `Hyper` + `Shift` + `f` | Toggle fullscreen |
| `Hyper` + `Ctrl` + `,` | Prev layout |
| `Hyper` + `Ctrl` + `.` | Next layout |
| **Gaps** ||
| `Hyper` + `Alt` + `=` | Increase gaps |
| `Hyper` + `Alt` + `-` | Decrease gaps |
| `Hyper` + `Alt` + `0` | Toggle gaps |
| `Hyper` + `Alt` + `Shift` + `0` | Reset gaps |
| **Misc** ||
| `Hyper` + `` ` `` | Scratchpad terminal |
| `Hyper` + `u` | Focus urgent |
| `Hyper` + `Shift` + `s` | Toggle sticky |
| `Hyper` + `Shift` + `c` | Center window |
| **cfacts** ||
| `Hyper` + `Shift` + `h` | Increase cfact |
| `Hyper` + `Shift` + `l` | Decrease cfact |
| `Hyper` + `Shift` + `o` | Reset cfact |
| **Media Keys** ||
| `XF86AudioMute` | Toggle mute |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioPlay` | Play/pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Prev track |
| `XF86MonBrightnessUp` | Brightness up |
| `XF86MonBrightnessDown` | Brightness down |
| **Screenshots** ||
| `Print` | Area to clipboard |
| `Shift` + `Print` | Area to file |
| `Ctrl` + `Print` | Window to clipboard |
| `Ctrl` + `Shift` + `Print` | Window to file |
| `Hyper` + `Print` | Fullscreen to clipboard |
| `Hyper` + `Shift` + `Print` | Fullscreen to file |
| **Screen Recording** ||
| `F9` | Record area |
| `Shift` + `F9` | Record window |
| `Ctrl` + `F9` | Record fullscreen |
| **Mouse** ||
| `Hyper` + `Left Click` | Move window |
| `Hyper` + `Middle Click` | Toggle floating |
| `Hyper` + `Right Click` | Resize window |

## Resources

- [DWM-Flexipatch](https://github.com/bakkeby/dwm-flexipatch)
- [dwmblocks](https://github.com/torrinfail/dwmblocks)
- [Arch Wiki - DWM](https://wiki.archlinux.org/title/dwm)
- [keyd](https://github.com/rvaiya/keyd)
