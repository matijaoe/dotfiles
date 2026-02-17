#!/bin/bash

# Create symlinks for all config files.
# Usage: bash scripts/symlinks.sh [profile]
# Example: bash scripts/symlinks.sh work

set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

info()    { printf "\033[34m→\033[0m %s\n" "$1"; }
success() { printf "\033[32m✓\033[0m %s\n" "$1"; }
warn()    { printf "\033[33m!\033[0m %s\n" "$1"; }

# Resolve profile
PROFILE="${1:-}"
if [[ -z "$PROFILE" && -f "$HOME/.dotfiles-profile" ]]; then
  PROFILE=$(cat "$HOME/.dotfiles-profile")
fi
if [[ -z "$PROFILE" ]]; then
  echo "Usage: symlinks.sh <profile>"
  echo "Or set profile via: echo work > ~/.dotfiles-profile"
  exit 1
fi

link_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      success "Already linked: $dest"
      return
    fi
    mv "$dest" "${dest}.bak"
    warn "Backed up: $dest → ${dest}.bak"
  fi

  ln -s "$src" "$dest"
  success "Linked: $dest → $src"
}

link_file "$DOTFILES/config/shell/.zshrc"          "$HOME/.zshrc"
link_file "$DOTFILES/config/shell/omz-aliases"     "$HOME/.local/share/zinit/plugins/omz-aliases"
link_file "$DOTFILES/config/starship.toml"         "$HOME/.config/starship.toml"
link_file "$DOTFILES/config/ghostty/config"        "$HOME/.config/ghostty/config"
link_file "$DOTFILES/config/ghostty/config"        "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
link_file "$DOTFILES/config/micro/settings.json"   "$HOME/.config/micro/settings.json"
link_file "$DOTFILES/config/micro/bindings.json"   "$HOME/.config/micro/bindings.json"
link_file "$DOTFILES/config/gh/config.yml"         "$HOME/.config/gh/config.yml"
link_file "$DOTFILES/config/gh-dash/config.yml"    "$HOME/.config/gh-dash/config.yml"
link_file "$DOTFILES/config/git/.gitconfig"        "$HOME/.gitconfig"
link_file "$DOTFILES/config/git/ignore"            "$HOME/.config/git/ignore"
link_file "$DOTFILES/config/ssh/config.$PROFILE"   "$HOME/.ssh/config"
link_file "$DOTFILES/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
link_file "$DOTFILES/config/opencode/theme.json"    "$HOME/.opencode.json"

success "All symlinks created"
