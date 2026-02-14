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

Dumps Homebrew packages, Dock layout, and npm globals for the active profile, then prompts to commit and push.

## What's inside

| Path                      | Description                                |
| ------------------------- | ------------------------------------------ |
| `brew/<profile>/Brewfile` | Homebrew packages per profile              |
| `dock/<profile>.txt`      | Pinned Dock apps per profile               |
| `dock/apply.sh`           | Apply a Dock config standalone             |
| `config/`                 | App configs (Starship, Ghostty, micro, gh) |
| `shell/.zshrc`            | Zsh config with Zinit                      |
| `git/`                    | Git config and global ignore               |
| `ssh/`                    | SSH config per profile                     |
| `macos.sh`                | macOS system defaults                      |
| `apps.md`                 | Apps installed outside Homebrew            |
| `npm-globals.txt`         | Global npm packages                        |

## Dock management

Dock configs are plain text files with one app path per line. On `save.sh`, the current Dock is dumped. On `setup.sh`, it's applied. Missing apps are skipped gracefully.

```bash
# Apply standalone
bash dock/apply.sh work

# Edit manually
nano dock/work.txt
```
