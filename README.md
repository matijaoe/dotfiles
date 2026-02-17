# dotfiles

Personal dotfiles with profile support (`work` / `personal`).

## Setup (new Mac)

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
bash setup.sh --work        # or --personal
bash setup.sh --work --macos  # also apply macOS defaults
```

## Save current state

```bash
bash save.sh
```

Dumps current state for the active profile, then prompts to commit and push.

| # | Step                  | Output                             |
|---| --------------------- | ---------------------------------- |
| 1 | Read profile          | from `~/.dotfiles-profile`         |
| 2 | Dump brew packages    | `packages/brew/<profile>/Brewfile` |
| 3 | Dump Dock pinned apps | `packages/dock/<profile>.txt`      |
| 4 | Dump npm globals      | `packages/npm-globals.txt`         |
| 5 | Dump pnpm globals     | `packages/pnpm-globals.txt`        |
| 6 | Git commit + push     | prompts y/N before pushing         |

## Setup flow

`setup.sh` runs these steps in order. Steps marked with a script link can also be run standalone.

| #  | Step                  | Script                                       |
| -- | --------------------- | -------------------------------------------- |
| 1  | Xcode CLI Tools       |                                              |
| 2  | Homebrew              |                                              |
| 3  | Zinit                 |                                              |
| 4  | Profile detection     |                                              |
| 5  | Brew packages         | [`scripts/brew-install.sh`](scripts/brew-install.sh) |
| 6  | Symlinks              | [`scripts/symlinks.sh`](scripts/symlinks.sh) |
| 7  | Node (via n)          |                                              |
| 8  | npm globals           |                                              |
| 9  | pnpm globals          |                                              |
| 10 | Curl-installed tools  | [`scripts/curl-tools.sh`](scripts/curl-tools.sh) |
| 11 | mise (work only)      |                                              |
| 12 | Claude Code           | [`scripts/claude-setup.sh`](scripts/claude-setup.sh) |
| 13 | macOS defaults        | [`scripts/macos-defaults.sh`](scripts/macos-defaults.sh) |
| 14 | Dock apps             | [`scripts/dock-apply.sh`](scripts/dock-apply.sh) |

## What's inside

| Path                               | Description                                |
| ---------------------------------- | ------------------------------------------ |
| `config/`                          | App configs (Starship, Ghostty, micro, gh) |
| `config/git/`                      | Git config and global ignore               |
| `config/shell/.zshrc`              | Zsh config with Zinit                      |
| `config/ssh/`                      | SSH config per profile                     |
| `config/claude/`                   | Claude Code settings, agents, skills       |
| `packages/brew/<profile>/Brewfile` | Homebrew packages per profile              |
| `packages/dock/<profile>.txt`      | Pinned Dock apps per profile               |
| `packages/npm-globals.txt`         | Global npm packages                        |
| `packages/pnpm-globals.txt`        | Global pnpm packages                       |
| `packages/curl-tools.sh`           | Tools installed via curl (bun, deno, etc.) |
| `packages/apps.md`                 | Apps installed outside Homebrew            |

## Dock management

Dock configs are plain text files with one app path per line. On `save.sh`, the current Dock is dumped. On `setup.sh`, it's applied. Missing apps are skipped gracefully.

```bash
# Apply standalone
bash scripts/dock-apply.sh work

# Edit manually
nano packages/dock/work.txt
```
