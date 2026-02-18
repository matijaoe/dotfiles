#!/bin/bash
# Apply a Dock configuration from a text file.
# Usage: bash scripts/dock-apply.sh [--work|--personal]
# Example: bash scripts/dock-apply.sh --work

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

section "Dock"

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

# Collect app names from dock file
APP_NAMES=()
APP_PATHS=()
while IFS= read -r app || [[ -n "$app" ]]; do
  [[ -z "$app" || "$app" == \#* ]] && continue
  name="${app##*/}"
  name="${name%.app}"
  APP_NAMES+=("$name")
  APP_PATHS+=("$app")
done < "$DOCK_FILE"

TOTAL=${#APP_NAMES[@]}

# Build desired app list
DESIRED=""
for path in "${APP_PATHS[@]}"; do
  DESIRED+="$path"$'\n'
done
DESIRED="${DESIRED%$'\n'}"

# Get current persistent dock apps (order-preserving)
CURRENT=$(dockutil --list 2>/dev/null \
  | awk -F'\t' '{print $2}' \
  | python3 -c "import sys, urllib.parse; [print(urllib.parse.unquote(l.strip().removeprefix('file://').rstrip('/'))) for l in sys.stdin]")

# Compare — skip if already correct (same apps, same order)
if [[ "$CURRENT" == "$DESIRED" ]]; then
  for name in "${APP_NAMES[@]}"; do
    success "$name"
  done
  summary "$TOTAL apps configured"
  exit 0
fi

# Disable "Show suggested and recent apps in Dock" to prevent re-injection
defaults write com.apple.dock show-recents -bool false 2>/dev/null || true

# Clear the dock
info "Applying dock layout..."
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array
defaults write com.apple.dock recent-apps -array 2>/dev/null || true

ADDED=0
SKIPPED=0

for i in "${!APP_PATHS[@]}"; do
  app="${APP_PATHS[$i]}"
  name="${APP_NAMES[$i]}"

  if [[ -d "$app" ]]; then
    dockutil --add "$app" --no-restart &>/dev/null
    success "$name"
    ((ADDED++)) || true
  else
    warn "$name (not found)"
    ((SKIPPED++)) || true
  fi
done

# Single Dock restart at the end
killall Dock 2>/dev/null || true

if [[ "$SKIPPED" -gt 0 ]]; then
  summary "$ADDED apps applied, $SKIPPED not found"
else
  summary "$ADDED apps applied"
fi
