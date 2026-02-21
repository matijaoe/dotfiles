# Dotfiles project rules

> This file (`.claude/CLAUDE.md`) applies only to the dotfiles project.
> The global `~/.claude/CLAUDE.md` lives in `config/claude/CLAUDE.md` and is symlinked by `scripts/claude-setup.sh`.

## Structure

- `config/` — all app configs, symlinked to their home directory destinations by `scripts/symlinks.sh` and `scripts/claude-setup.sh`
- `packages/` — package lists and definitions (Brewfile, npm/pnpm globals, curl-tools, dock layouts)
- `scripts/` — standalone runnable scripts, also called by `setup.sh`
- `setup.sh` and `save.sh` live at root

## Scripts

- Scripts use `#!/bin/bash` shebangs
- Naming convention: `<thing>-<action>.sh` (e.g. `brew-install.sh`, `dock-apply.sh`)
- Standalone scripts should accept `[profile]` as argument and fall back to `~/.dotfiles-profile`
- Helpers (info, success, warn) are defined per script — no shared lib
- Use `set -e` in scripts that should fail fast

## When making changes

- Update `README.md` when adding/moving/removing files, scripts, setup steps, or CLI flags/arguments — this includes any new options added to `save.sh`, `setup.sh`, or other entry points
- Update `setup.sh` step numbers if the order changes
- When extracting a step from `setup.sh` into a standalone script, keep `setup.sh` calling it
- When adding a new config, add the symlink to both `scripts/symlinks.sh` and verify it in `setup.sh`
- When adding a new curl tool, add it to `packages/curl-tools.sh` only — the scripts handle the rest
- Paths in scripts use `$DOTFILES` variable, not hardcoded absolute paths

## Profiles

- Two profiles: `work` and `personal`
- Profile-specific files go in subdirectories (e.g. `packages/brew/work/`, `packages/dock/work.txt`)
- Profile is stored in `~/.dotfiles-profile` and read by `save.sh` and standalone scripts
