# Dotfiles

![Preview Image](./preview.png)

## Features

- **Desktop**: COSMIC
- **Terminal**: WezTerm
- **Shell**: Zsh
- **Editor**: [Emacs](https://codeberg.org/aileks/emacs.d)
- **PDF viewer**: Zathura
- **Media player**: mpv

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

## Install Script Flags

```bash
./install.sh              # Interactive menu
./install.sh 1            # Full setup (symlinks + build)
./install.sh 2            # Symlink only
./install.sh 3            # Packages only
./install.sh 4            # Zsh setup only
./install.sh --dry-run 1  # Preview changes
```

## Data Science Toolset

`install_packages` now prompts for `install_data_tools`.

When accepted, installer installs/updates:
- `uv`
- Miniconda (`$HOME/miniconda3`)
- `r-base`
- RStudio Desktop

Conda policy:
- shell hook path uses `$HOME/miniconda3`
- `auto_activate_base=false`

## Resources

- [COSMIC](https://github.com/pop-os/cosmic-epoch)
- [keyd](https://github.com/rvaiya/keyd)
- [Helium](https://github.com/imputnet/helium-linux)
- [zplug](https://github.com/zplug/zplug)

## License

[MIT](./LICENSE)
