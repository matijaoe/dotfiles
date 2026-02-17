#!/bin/bash
# Apply a Dock configuration from a text file.
# Usage: bash scripts/dock-apply.sh [--work|--personal]
# Example: bash scripts/dock-apply.sh --work

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

# Resolve profile
PROFILE="$(require_profile "$@")"

DOCK_FILE="$DOTFILES/packages/dock/${PROFILE}.txt"

if [[ ! -f "$DOCK_FILE" ]]; then
  echo "No dock config found at $DOCK_FILE"
  exit 1
fi

if ! command -v dockutil &>/dev/null; then
  echo "dockutil not found — install with: brew install dockutil"
  exit 1
fi

# Build desired app list (skip empty lines and comments)
DESIRED=""
while IFS= read -r app || [[ -n "$app" ]]; do
  [[ -z "$app" || "$app" == \#* ]] && continue
  DESIRED+="$app"$'\n'
done < "$DOCK_FILE"
DESIRED="${DESIRED%$'\n'}"

# Get current persistent dock apps (order-preserving)
CURRENT=$(dockutil --list 2>/dev/null \
  | awk -F'\t' '{print $2}' \
  | python3 -c "import sys, urllib.parse; [print(urllib.parse.unquote(l.strip().removeprefix('file://').rstrip('/'))) for l in sys.stdin]")

# Compare — skip if already correct (same apps, same order)
if [[ "$CURRENT" == "$DESIRED" ]]; then
  success "Dock already configured ($(echo "$DESIRED" | wc -l | tr -d ' ') apps)"
  exit 0
fi

# Disable "Show suggested and recent apps in Dock" to prevent re-injection
defaults write com.apple.dock show-recents -bool false 2>/dev/null || true

# Clear the dock: use defaults write to empty the arrays, then let
# dockutil add on top. Do NOT kill cfprefsd here — that causes a race
# where the Dock process writes running apps back into the plist.
info "Applying dock layout..."
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array
defaults write com.apple.dock recent-apps -array 2>/dev/null || true

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
