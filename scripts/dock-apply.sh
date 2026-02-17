#!/bin/bash
# Apply a Dock configuration from a text file.
# Usage: bash scripts/dock-apply.sh [profile]
# Example: bash scripts/dock-apply.sh work

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

info()    { printf "  \033[34m•\033[0m %s\n" "$1"; }
success() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn()    { printf "  \033[33m!\033[0m %s\n" "$1"; }

# Resolve profile
PROFILE="${1:-}"
if [[ -z "$PROFILE" && -f "$HOME/.dotfiles-profile" ]]; then
  PROFILE="$(cat "$HOME/.dotfiles-profile")"
fi
if [[ -z "$PROFILE" ]]; then
  echo "Usage: dock-apply.sh <profile>"
  echo "Or set profile via: echo work > ~/.dotfiles-profile"
  exit 1
fi

DOCK_FILE="$DOTFILES/packages/dock/${PROFILE}.txt"
if [[ ! -f "$DOCK_FILE" ]]; then
  echo "No dock config found at $DOCK_FILE"
  exit 1
fi

if ! command -v dockutil &>/dev/null; then
  echo "dockutil not found — install with: brew install dockutil"
  exit 1
fi

# Optional but recommended: disable "recent apps" so macOS doesn't re-inject items.
# (This is the "Show suggested and recent apps in Dock" toggle.)
defaults write com.apple.dock show-recents -bool false >/dev/null 2>&1 || true

info "Clearing current layout..."
dockutil --remove all --no-restart &>/dev/null || true

# Belt & suspenders: ensure Dock sections are truly empty.
# This helps if something else keeps merging items back in.
defaults write com.apple.dock persistent-apps -array >/dev/null
defaults write com.apple.dock persistent-others -array >/dev/null
defaults write com.apple.dock recent-apps -array >/dev/null 2>&1 || true

success "Cleared"

echo ""
info "Adding apps..."

ADDED=0
SKIPPED=0

# Read file safely (handles spaces like "Notion Calendar.app")
while IFS= read -r app || [[ -n "$app" ]]; do
  [[ -z "$app" || "$app" == \#* ]] && continue

  name="${app##*/}"
  name="${name%.app}"

  if [[ -d "$app" ]]; then
    dockutil --add "$app" --no-restart &>/dev/null
    success "$name"
    ((ADDED++)) || true
  else
    warn "$name (not found)"
    ((SKIPPED++)) || true
  fi
done < "$DOCK_FILE"

# Single restart at the end
killall Dock 2>/dev/null || true

echo ""
if [[ "$SKIPPED" -gt 0 ]]; then
  printf "\033[32m✓\033[0m %d apps added, %d skipped\n" "$ADDED" "$SKIPPED"
else
  printf "\033[32m✓\033[0m %d apps added\n" "$ADDED"
fi
