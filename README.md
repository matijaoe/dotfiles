# dotfiles

Personal dotfiles with profile support for **work** and **personal** machines.

## Quick start

```sh
git clone <repo> ~/dotfiles
cd ~/dotfiles
./setup.sh                    # prompts to pick: work / personal
./setup.sh --work             # skip prompt
./setup.sh --work --macos     # also apply macOS system defaults
```

### Profiles

| Flag           | Description                              |
| -------------- | ---------------------------------------- |
| `--work`       | Work Brewfile, work SSH config, mise tools |
| `--personal`   | Personal Brewfile, personal SSH config   |
| _(no flag)_    | Prompts to choose (reads `~/.dotfiles-profile` if set) |
| `--macos`      | Apply macOS system defaults (optional, any profile) |

The chosen profile is saved to `~/.dotfiles-profile` and reused by `save.sh` and standalone scripts.

## Save current state

```sh
./save.sh    # or: save (zsh alias)
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

`setup.sh` runs these steps in order. Steps with a link can also be run standalone.

| #  | Step                 | Standalone script                                         | Notes                             |
| -- | -------------------- | --------------------------------------------------------- | --------------------------------- |
| 1  | Xcode CLI Tools      |                                                           |                                   |
| 2  | Homebrew             |                                                           |                                   |
| 3  | Zinit                |                                                           |                                   |
| 4  | Profile detection    |                                                           | prompts if no flag passed         |
| 5  | Brew packages        | [`brew-install.sh`](scripts/brew-install.sh) `[profile]`  |                                   |
| 6  | Symlinks             | [`symlinks.sh`](scripts/symlinks.sh) `[profile]`          |                                   |
| 7  | Node (via n)         |                                                           |                                   |
| 8  | npm globals          |                                                           |                                   |
| 9  | pnpm globals         |                                                           |                                   |
| 10 | Curl-installed tools | [`curl-tools.sh`](scripts/curl-tools.sh)                  |                                   |
| 11 | mise                 |                                                           | work profile only                 |
| 12 | Claude Code          | [`claude-setup.sh`](scripts/claude-setup.sh) `[-y]`       | interactive, `-y` skips prompts   |
| 13 | macOS defaults       | [`macos-defaults.sh`](scripts/macos-defaults.sh)          | only runs with `--macos` flag     |
| 14 | Dock layout          | [`dock-apply.sh`](scripts/dock-apply.sh) `<profile>`      |                                   |

Standalone scripts read profile from `~/.dotfiles-profile` when no argument is given.

## Structure

```
dotfiles/
├── setup.sh                          # full setup entry point
├── save.sh                           # save state entry point
│
├── config/                           # all app configs
│   ├── claude/                       # Claude Code (settings, agents, skills)
│   ├── gh/                           # GitHub CLI
│   ├── gh-dash/                      # GitHub dashboard
│   ├── ghostty/                      # terminal emulator
│   ├── git/                          # .gitconfig + global ignore
│   ├── micro/                        # text editor
│   ├── shell/                        # .zshrc + aliases + CLI reference
│   ├── ssh/                          # SSH config per profile
│   └── starship.toml                 # prompt theme
│
├── packages/                         # all package definitions
│   ├── brew/<profile>/Brewfile       # Homebrew packages
│   ├── dock/<profile>.txt            # Dock pinned apps
│   ├── npm-globals.txt               # global npm packages
│   ├── pnpm-globals.txt              # global pnpm packages
│   ├── curl-tools.sh                 # tools installed via curl
│   └── apps.md                       # apps installed outside Homebrew
│
└── scripts/                          # standalone runnable scripts
    ├── brew-install.sh
    ├── claude-setup.sh
    ├── curl-tools.sh
    ├── dock-apply.sh
    ├── macos-defaults.sh
    └── symlinks.sh
```

## Dock management

Dock layouts are plain text files with one app path per line. `save.sh` dumps the current layout, `setup.sh` applies it. Missing apps are skipped.

```sh
./scripts/dock-apply.sh work          # apply standalone
micro packages/dock/work.txt          # edit manually
```
