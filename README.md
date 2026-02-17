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

Dumps Homebrew packages, Dock layout, npm globals, and pnpm globals for the active profile, then prompts to commit and push.

## What's inside

| Path                               | Description                                |
| ---------------------------------- | ------------------------------------------ |
| `config/`                          | App configs (Starship, Ghostty, micro, gh) |
| `config/git/`                      | Git config and global ignore               |
| `config/shell/.zshrc`              | Zsh config with Zinit                      |
| `config/ssh/`                      | SSH config per profile                     |
| `packages/brew/<profile>/Brewfile` | Homebrew packages per profile              |
| `packages/dock/<profile>.txt`      | Pinned Dock apps per profile               |
| `packages/npm-globals.txt`         | Global npm packages                        |
| `packages/pnpm-globals.txt`        | Global pnpm packages                       |
| `packages/curl-tools.sh`           | Tools installed via curl (bun, deno, etc.) |
| `packages/apps.md`                 | Apps installed outside Homebrew            |
| `config/claude/`                   | Claude Code settings, agents, skills       |
| `scripts/claude-setup.sh`         | Claude Code setup (standalone or via setup) |
| `scripts/macos.sh`                 | macOS system defaults                      |
| `scripts/dock-apply.sh`            | Apply a Dock config standalone             |

## Dock management

Dock configs are plain text files with one app path per line. On `save.sh`, the current Dock is dumped. On `setup.sh`, it's applied. Missing apps are skipped gracefully.

```bash
# Apply standalone
bash scripts/dock-apply.sh work

# Edit manually
nano packages/dock/work.txt
```
