#!/bin/bash

# Set up Claude Code configuration (settings, agents, statusline, etc.)
# Usage: bash scripts/claude-setup.sh        # interactive, prompts for each step
#        bash scripts/claude-setup.sh -y     # accept all defaults

set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_SRC="$DOTFILES/config/claude"
CLAUDE_DEST="$HOME/.claude"
AUTO_YES=false

for arg in "$@"; do
  case "$arg" in
    -y|--yes) AUTO_YES=true ;;
  esac
done

# ============================================================
# Helpers
# ============================================================
info()    { printf "  \033[34m•\033[0m %s\n" "$1"; }
success() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn()    { printf "  \033[33m!\033[0m %s\n" "$1"; }
section() { printf "\n\033[1;36m➤\033[0m %s\n" "$1"; }

confirm() {
  if [[ "$AUTO_YES" == true ]]; then
    return 0
  fi
  local prompt="$1"
  local reply
  printf "%s [Y/n] " "$prompt"
  read -r reply
  [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]
}

LINKED=0
CREATED=0

link_file() {
  local src="$1"
  local dest="$2"
  local name="$(basename "$dest")"

  mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      ((LINKED++)) || true
      return
    fi
    mv "$dest" "${dest}.bak"
    warn "$name (backed up existing)"
  fi

  ln -s "$src" "$dest"
  success "$name"
  ((CREATED++)) || true
}

section "Claude Code"

# Settings
if confirm "Link Claude settings.json?"; then
  link_file "$CLAUDE_SRC/settings.json" "$CLAUDE_DEST/settings.json"
fi

# CLAUDE.md
if confirm "Link global CLAUDE.md?"; then
  link_file "$CLAUDE_SRC/CLAUDE.md" "$CLAUDE_DEST/CLAUDE.md"
fi

# Statusline
if confirm "Link statusline-command.py?"; then
  link_file "$CLAUDE_SRC/statusline-command.py" "$CLAUDE_DEST/statusline-command.py"
fi

# Agents
if confirm "Link custom agents?"; then
  mkdir -p "$CLAUDE_DEST/agents"
  for agent in "$CLAUDE_SRC/agents/"*.md; do
    [[ -f "$agent" ]] || continue
    name="$(basename "$agent")"
    link_file "$agent" "$CLAUDE_DEST/agents/$name"
  done
fi

# Skills
if confirm "Link skills directory?"; then
  link_file "$CLAUDE_SRC/skills" "$CLAUDE_DEST/skills"
fi

echo ""
TOTAL=$((LINKED + CREATED))
if [[ "$CREATED" -eq 0 ]]; then
  printf "\033[32m✓\033[0m %d/%d up to date\n" "$TOTAL" "$TOTAL"
else
  printf "\033[32m✓\033[0m %d created, %d already linked\n" "$CREATED" "$LINKED"
fi
