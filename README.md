# dotfiles

Personal dotfiles with profile support for **work** and **personal** machines.

## Quick start

```sh
curl -fsSL raw.githubusercontent.com/matijaoe/dotfiles/main/install.sh | bash
```

Or manually:

```sh
git clone https://github.com/matijaoe/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh --work    # or --personal
```

After setup, the `dots` CLI is available. Run `dots help` for full usage.

## Commands

```sh
dots setup [--work|--personal] [-y]  # full system setup
dots save                        # save current state to repo
dots run <script> [profile]      # run individual script
dots run brew                    # install Homebrew packages
dots run symlinks                # create config symlinks
dots run dock                    # apply Dock layout
dots run macos                   # apply macOS system defaults
dots run claude                  # setup Claude Code configs
dots run cursor                  # restore Cursor settings
dots run curl                    # install curl-based tools
```

## Profiles

| Flag         | Includes                                   |
| ------------ | ------------------------------------------ |
| `--work`     | Work Brewfile, work SSH config, mise tools |
| `--personal` | Personal Brewfile, personal SSH config     |

Profile-specific files live in subdirectories: `packages/brew/work/`, `packages/dock/work.txt`, `config/ssh/config.work`.

Profile is resolved in order:

1. Explicit flag
2. Saved in `~/.dotfiles-profile`
3. Interactive prompt (first setup only)

## Setup flow

`dots setup` runs these steps in order:

| #   | Step              | Standalone          | Notes                            |
| --- | ----------------- | ------------------- | -------------------------------- |
| 1   | Xcode CLI Tools   |                     |                                  |
| 2   | Homebrew          |                     |                                  |
| 3   | Antidote          |                     |                                  |
| 4   | Profile detection |                     | prompts if no profile set        |
| 5   | Brew packages     | `dots run brew`     | incl. Cursor extensions          |
| 6   | Symlinks          | `dots run symlinks` | shell, git, ssh, claude, editors |
| 7   | Cursor            | `dots run cursor`   | diffs before applying; prompts if live changes would be lost; backs up on override |
| 8   | Node (via n)      |                     |                                  |
| 9   | npm globals       |                     |                                  |
| 10  | pnpm globals      |                     |                                  |
| 11  | Curl tools        | `dots run curl`     |                                  |
| 12  | mise              |                     | work profile only                |
| 13  | macOS defaults    | `dots run macos`    |                                  |
| 14  | Dock layout       | `dots run dock`     |                                  |

## Save flow

`dots save` snapshots the current machine state and prompts to commit and push.

| #   | Step                  | Output                             |
| --- | --------------------- | ---------------------------------- |
| 1   | Read profile          | from `~/.dotfiles-profile`         |
| 2   | Dump brew packages    | `packages/brew/<profile>/Brewfile` |
| 3   | Dump Dock pinned apps | `packages/dock/<profile>.txt`      |
| 4   | Dump npm globals      | `packages/npm-globals.txt`         |
| 5   | Dump pnpm globals     | `packages/pnpm-globals.txt`        |
| 6   | Copy Cursor settings  | `config/cursor/settings.json`      |
| 7   | Copy Cursor keybinds  | `config/cursor/keybindings.json`   |
| 8   | Git commit + push     | prompts y/N                        |
