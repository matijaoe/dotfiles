# dotfiles

Personal dotfiles with profile support for **work** and **personal** machines.

## Quick start

```sh
git clone <repo> ~/dotfiles
cd ~/dotfiles
./setup.sh                    # prompts to pick: work / personal
./setup.sh --work             # skip prompt, use work profile
```

After setup, the `dots` CLI is available globally:

```sh
dots setup [--work|--personal]   # full system setup
dots save                        # save current state
dots run <script> [args]         # run individual setup script
```

Available scripts via `dots run`:

```sh
dots run brew [profile]          # install Homebrew packages
dots run symlinks [profile]      # create config symlinks
dots run dock [profile]          # apply Dock layout
dots run claude [-y]             # setup Claude Code (interactive)
dots run macos                   # apply macOS system defaults
dots run curl                    # install curl-based tools
```

Scripts read profile from `~/.dotfiles-profile` when not specified.

## Profiles

| Flag           | Description                              |
| -------------- | ---------------------------------------- |
| `--work`       | Work Brewfile, work SSH config, mise tools |
| `--personal`   | Personal Brewfile, personal SSH config   |
| _(no flag)_    | Prompts to choose (reads `~/.dotfiles-profile` if set) |

## Save current state

```sh
dots save
```

Snapshots the current machine state into the repo, then prompts to commit and push.

| # | Step                  | Output                             |
|---| --------------------- | ---------------------------------- |
| 1 | Read profile          | from `~/.dotfiles-profile`         |
| 2 | Dump brew packages    | `packages/brew/<profile>/Brewfile` |
| 3 | Dump Dock pinned apps | `packages/dock/<profile>.txt`      |
| 4 | Dump npm globals      | `packages/npm-globals.txt`         |
| 5 | Dump pnpm globals     | `packages/pnpm-globals.txt`        |
| 6 | Git commit + push     | prompts y/N                        |

## Setup flow

`dots setup` runs these steps in order:

| #  | Step                 | Standalone command      | Notes                             |
| -- | -------------------- | ------------------- | --------------------------------- |
| 1  | Xcode CLI Tools      |                     |                                   |
| 2  | Homebrew             |                     |                                   |
| 3  | Zinit                |                     |                                   |
| 4  | Profile detection    |                     | prompts if no `--work`/`--personal` |
| 5  | Brew packages        | `dots run brew`         |                                   |
| 6  | Configs              | `dots run symlinks`     | shell, git, ssh, claude, editors, opencode |
| 7  | Node (via n)         |                         |                                   |
| 8  | npm globals          |                         |                                   |
| 9  | pnpm globals         |                         |                                   |
| 10 | Curl-installed tools | `dots run curl`         |                                   |
| 11 | mise                 |                         | work profile only                 |
| 12 | macOS defaults       | `dots run macos`        |                                   |
| 13 | Dock layout          | `dots run dock`         |                                   |

## Structure

```
dotfiles/
├── dots                              # CLI entry point (symlinked to ~/.local/bin/dots)
├── setup.sh                          # full setup (called by: dots setup)
├── save.sh                           # save state (called by: dots save)
│
├── config/                           # all app configs
│   ├── claude/                       # Claude Code (settings, agents, skills) → ~/.claude/
│   ├── gh/                           # GitHub CLI → ~/.config/gh/
│   ├── gh-dash/                      # GitHub dashboard → ~/.config/gh-dash/
│   ├── ghostty/                      # terminal emulator → ~/.config/ghostty/
│   ├── git/                          # .gitconfig + global ignore → ~/
│   ├── micro/                        # text editor → ~/.config/micro/
│   ├── opencode/                     # OpenCode settings → ~/.config/opencode/ & ~/.opencode.json
│   ├── shell/                        # .zshrc + aliases + CLI reference → ~/
│   ├── ssh/                          # SSH config per profile → ~/.ssh/config
│   └── starship.toml                 # prompt theme → ~/.config/starship.toml
│
├── packages/                         # all package definitions
│   ├── brew/<profile>/Brewfile       # Homebrew packages
│   ├── dock/<profile>.txt            # Dock pinned apps
│   ├── npm-globals.txt               # global npm packages
│   ├── pnpm-globals.txt              # global pnpm packages
│   ├── curl-tools.sh                 # tools installed via curl (bun, deno, etc.)
│   └── apps.md                       # apps installed outside Homebrew (App Store)
│
└── scripts/                          # standalone scripts (called by dots run)
    ├── brew-install.sh               # install Homebrew packages
    ├── claude-setup.sh               # interactive Claude Code setup (standalone only)
    ├── curl-tools.sh                 # install curl-based tools
    ├── dock-apply.sh                 # apply Dock layout
    ├── macos-defaults.sh             # apply macOS system defaults
    └── symlinks.sh                   # create all config symlinks
```

## Dock management

Dock layouts are plain text files with one app path per line.

```sh
dots run dock                        # apply layout (uses saved profile)
dots run dock work                   # or specify profile explicitly
micro packages/dock/work.txt         # edit manually
```
