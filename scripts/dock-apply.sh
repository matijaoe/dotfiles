#!/bin/bash
# Apply a Dock configuration from a text file.
# Usage: bash scripts/dock-apply.sh [profile]
# Example: bash scripts/dock-apply.sh work

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

# Resolve profile
PROFILE="$(require_profile "$(basename "$0")" "${1:-}")"

DOCK_FILE="$DOTFILES/packages/dock/${PROFILE}.txt"

if [[ ! -f "$DOCK_FILE" ]]; then
  echo "No dock config found at $DOCK_FILE"
  exit 1
fi

if ! command -v dockutil &>/dev/null; then
  echo "dockutil not found — install with: brew install dockutil"
  exit 1
fi

# Disable "Show suggested and recent apps in Dock" to prevent re-injection
defaults write com.apple.dock show-recents -bool false 2>/dev/null || true

info "Clearing current dock..."

# Remove all via dockutil
dockutil --remove all --no-restart &>/dev/null || true

# Belt & suspenders: force all dock arrays empty via defaults
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array
defaults write com.apple.dock recent-apps -array 2>/dev/null || true

# CRITICAL: flush the preferences cache NOW, before any adds.
# Without this, dockutil reads stale cached data and merges old items back in.
killall cfprefsd 2>/dev/null || true

success "Cleared"
echo ""

info "Adding apps..."
ADDED=0
SKIPPED=0

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

# Single Dock restart at the end to apply everything at once
killall Dock 2>/dev/null || true

echo ""
if [[ "$SKIPPED" -gt 0 ]]; then
  printf "\033[32m✓\033[0m %d apps added, %d skipped\n" "$ADDED" "$SKIPPED"
else
  printf "\033[32m✓\033[0m %d apps added\n" "$ADDED"
fi
