#!/bin/bash

# Apply a Dock configuration from a text file.
# Usage: bash scripts/dock-apply.sh <profile>
# Example: bash scripts/dock-apply.sh work

set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE="${1:?Usage: scripts/dock-apply.sh <profile>}"
DOCK_FILE="$DOTFILES/packages/dock/${PROFILE}.txt"

if [[ ! -f "$DOCK_FILE" ]]; then
  echo "No dock config found at $DOCK_FILE"
  exit 1
fi

if ! command -v dockutil &>/dev/null; then
  echo "dockutil not found — install with: brew install dockutil"
  exit 1
fi

echo "Applying Dock config: $DOCK_FILE"

dockutil --remove all --no-restart

while IFS= read -r app || [[ -n "$app" ]]; do
  # Skip empty lines and comments
  [[ -z "$app" || "$app" == \#* ]] && continue

  if [[ -d "$app" ]]; then
    dockutil --add "$app" --no-restart
  else
    echo "  ⚠ Skipping (not found): $app"
  fi
done < "$DOCK_FILE"

killall Dock
echo "Dock updated."
