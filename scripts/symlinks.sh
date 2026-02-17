#!/bin/bash

# Create symlinks for all config files.
# Usage: bash scripts/symlinks.sh [profile]
# Example: bash scripts/symlinks.sh work

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

# Resolve profile
PROFILE="$(require_profile "$(basename "$0")" "${1:-}")"

TOTAL=0
CREATED=0

link_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  ((TOTAL++)) || true

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      return 0
    fi
    mv "$dest" "${dest}.bak"
  fi

  ln -s "$src" "$dest"
  ((CREATED++)) || true
  return 1
}

# Shell
link_file "$DOTFILES/config/shell/.zshrc"          "$HOME/.zshrc"
link_file "$DOTFILES/config/shell/omz-aliases"     "$HOME/.local/share/zinit/plugins/omz-aliases"
link_file "$DOTFILES/config/shell/completions"     "$HOME/.config/shell/completions"
success "Shell"

# Git
link_file "$DOTFILES/config/git/.gitconfig"        "$HOME/.gitconfig"
link_file "$DOTFILES/config/git/ignore"            "$HOME/.config/git/ignore"
success "Git"

# SSH
link_file "$DOTFILES/config/ssh/config.$PROFILE"   "$HOME/.ssh/config"
success "SSH ($PROFILE)"

# Starship
link_file "$DOTFILES/config/starship.toml"         "$HOME/.config/starship.toml"
success "Starship"

# Ghostty
link_file "$DOTFILES/config/ghostty/config"        "$HOME/.config/ghostty/config"
link_file "$DOTFILES/config/ghostty/config"        "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
success "Ghostty"

# Micro
link_file "$DOTFILES/config/micro/settings.json"   "$HOME/.config/micro/settings.json"
link_file "$DOTFILES/config/micro/bindings.json"   "$HOME/.config/micro/bindings.json"
success "Micro"

# GitHub
link_file "$DOTFILES/config/gh/config.yml"         "$HOME/.config/gh/config.yml"
link_file "$DOTFILES/config/gh-dash/config.yml"    "$HOME/.config/gh-dash/config.yml"
success "GitHub"

# OpenCode
link_file "$DOTFILES/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
link_file "$DOTFILES/config/opencode/theme.json"    "$HOME/.opencode.json"
success "OpenCode"

# Claude Code
link_file "$DOTFILES/config/claude/settings.json"   "$HOME/.claude/settings.json"
link_file "$DOTFILES/config/claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"
link_file "$DOTFILES/config/claude/statusline-command.py" "$HOME/.claude/statusline-command.py"
link_file "$DOTFILES/config/claude/skills"          "$HOME/.claude/skills"
mkdir -p "$HOME/.claude/agents"
for agent in "$DOTFILES/config/claude/agents/"*.md; do
  [[ -f "$agent" ]] || continue
  link_file "$agent" "$HOME/.claude/agents/$(basename "$agent")"
done
success "Claude Code"

# dots CLI
link_file "$DOTFILES/dots" "$HOME/.local/bin/dots"
success "dots CLI"

echo ""
LINKED=$((TOTAL - CREATED))
if [[ "$CREATED" -eq 0 ]]; then
  printf "\033[32m✓\033[0m %d/%d configs up to date\n" "$TOTAL" "$TOTAL"
else
  printf "\033[32m✓\033[0m %d created, %d already linked\n" "$CREATED" "$LINKED"
fi
