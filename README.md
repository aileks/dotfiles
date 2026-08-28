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

## Data development

Use `uv` for project Python versions, environments, and dependencies. DuckDB and SQLite are available as local command-line databases. Keep dbt Core and its database adapter in each project's `pyproject.toml`.

PostgreSQL 18 runs in a rootless Podman container and starts with the user session. Run `psql-local` to connect with a passwordless user and database matching the desktop username. Manage the service with `systemctl --user` using the `postgres-local.service` unit.

The PostgreSQL data volume persists across container replacement. It is development data and is excluded from the home backup.

## Keybinds

Press `Super + Shift + /` or run `keybinds-menu` to search the live Hyprland bindings and their descriptions.

For voice dictation, hold `F9` while speaking, or press `Super + Ctrl + X` to toggle recording.
