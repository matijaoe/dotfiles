#!/bin/bash

# Install Homebrew packages from Brewfile and configure autoupdate.
# Usage: bash scripts/brew-install.sh [--work|--personal]
# Example: bash scripts/brew-install.sh --work

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
BREW_AUTOUPDATE_INTERVAL=86400  # 24 hours in seconds

# Resolve profile
PROFILE="$(require_profile "$@")"

# Install packages
BREWFILE="$DOTFILES/packages/brew/$PROFILE/Brewfile"
if [[ ! -f "$BREWFILE" ]]; then
  warn "No Brewfile found at $BREWFILE"
  exit 1
fi

_brew_tmp=$(mktemp)
brew bundle --file="$BREWFILE" > "$_brew_tmp" 2>&1 || true

# Show only installs and upgrades with proper formatting
while IFS= read -r line; do
  if [[ "$line" =~ ^Installing[[:space:]](.+) ]]; then
    info "Installing ${BASH_REMATCH[1]}..."
  elif [[ "$line" =~ ^Upgrading[[:space:]](.+) ]]; then
    info "Upgrading ${BASH_REMATCH[1]}..."
  fi
done < "$_brew_tmp"

USING=$(grep -cE "^Using " "$_brew_tmp" || true)
INSTALLING=$(grep -cE "^Installing " "$_brew_tmp" || true)
UPGRADING=$(grep -cE "^Upgrading " "$_brew_tmp" || true)
rm -f "$_brew_tmp"

if [[ "$INSTALLING" -eq 0 && "$UPGRADING" -eq 0 ]]; then
  success "$USING packages up to date"
else
  success "$INSTALLING installed, $UPGRADING upgraded, $USING already up to date"
fi

# Configure autoupdate
HOURS=$((BREW_AUTOUPDATE_INTERVAL / 3600))
if brew autoupdate status 2>/dev/null | grep -q "installed and running"; then
  success "Autoupdate running (every ${HOURS}h)"
else
  info "Configuring autoupdate (every ${HOURS}h)..."
  brew autoupdate start "$BREW_AUTOUPDATE_INTERVAL" --upgrade --cleanup &>/dev/null
  success "Autoupdate configured"
fi
