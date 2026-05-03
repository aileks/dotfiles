# Noctalia config seed

This directory holds the Ashen-themed seed for Noctalia's user config.

## Files

- `settings.json` — main shell settings (theming, panel layout, modules). **Not yet captured** — see workflow below.

## Workflow

Noctalia's GUI panel rewrites `~/.config/noctalia/settings.json` continuously
as you tweak the shell. Tracking that file as a symlink would dirty this repo
on every drag/click. Instead, `setup.sh::seed_noctalia_config()` copies the
seed here into `~/.config/noctalia/` only when the destination doesn't exist
(or backs up first if it does and content differs).

## Capturing the Ashen seed

The exact `settings.json` schema isn't documented well enough to hand-author.
First-time setup:

1. Let `setup.sh` install `noctalia-shell` and start it via niri.
2. Open Noctalia's settings panel. Switch theme mode to manual / predefined
   (whichever disables matugen). Tune colors to the Ashen palette:
   - background `#121212`
   - primary accent `#c4693d`
   - error/critical `#b14242`
   - foreground `#d5d5d5`
   - reference `mako/config`, `fuzzel/fuzzel.ini`, `waybar/style.css` for the
     full palette already in use.
3. Copy the resulting file back into the repo:
   ```
   cp ~/.config/noctalia/settings.json ~/.dotfiles/noctalia/settings.json
   ```
4. Commit. Future fresh installs will be hydrated automatically.

When you later tweak the theme through the GUI, repeat step 3 to re-capture.
