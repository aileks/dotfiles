# Dotfiles

Personal dotfiles plus a distro-aware software installer for Arch-based, Fedora-based, and Ubuntu-based Linux systems.

## Installer Behavior

The installer detects the distro family from `/etc/os-release`, installs `git` first if it is missing, then uses a TUI to choose software by category.

It supports Arch-based, Fedora-based, and Ubuntu-based distros. Unsupported systems exit before installing software.

## Quick Start

```bash
curl -fsSL https://aileks.dev/linux | bash
```

Or manually:

```bash
git clone https://codeberg.org/aileks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

## Options

```bash
./setup.sh --list
./setup.sh --dry-run
./setup.sh --no-tui
```
