# macOS Setup Script & Dotfiles

Automated setup script for macOS that installs my needed software and sets up dotfiles.

## Usage

```sh
zsh -c "$(curl -fsSL https://aileks.dev/mac)"

# Or clone the repo
git clone https://github.com/aileks/dotfiles.github.git
cd dotfiles
git submodule update --init --recursive
./install.zsh
```

## CLI Options

| Option          | Description                           |
| --------------- | ------------------------------------- |
| `-h, --help`    | Show help message                     |
| `-d, --dry-run` | Run in dry-run mode (no changes made) |
| `--debug`       | Enable debug output                   |
| `1`             | Perform full macOS setup              |
| `2`             | Update and symlink dotfiles only      |

If no option is provided, an interactive menu is displayed.
