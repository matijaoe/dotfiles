#!/bin/bash

# Install Homebrew packages from Brewfile and configure autoupdate.
# Usage: bash scripts/brew-install.sh [profile]
# Example: bash scripts/brew-install.sh work

set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
BREW_AUTOUPDATE_INTERVAL=86400  # 24 hours in seconds

info()    { printf "\033[34m→\033[0m %s\n" "$1"; }
success() { printf "\033[32m✓\033[0m %s\n" "$1"; }
warn()    { printf "\033[33m!\033[0m %s\n" "$1"; }

# Resolve profile
PROFILE="${1:-}"
if [[ -z "$PROFILE" && -f "$HOME/.dotfiles-profile" ]]; then
  PROFILE=$(cat "$HOME/.dotfiles-profile")
fi
if [[ -z "$PROFILE" ]]; then
  echo "Usage: brew-install.sh <profile>"
  echo "Or set profile via: echo work > ~/.dotfiles-profile"
  exit 1
fi

# Install packages
BREWFILE="$DOTFILES/packages/brew/$PROFILE/Brewfile"
if [[ ! -f "$BREWFILE" ]]; then
  warn "No Brewfile found at $BREWFILE"
  exit 1
fi

info "Installing from Brewfile ($PROFILE)..."

_brew_tmp=$(mktemp)
brew bundle --file="$BREWFILE" > "$_brew_tmp" 2>&1 || true

# Show only installs and upgrades
grep -E "^(Installing|Upgrading)" "$_brew_tmp" || true

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
info "Configuring brew autoupdate..."
brew autoupdate stop &>/dev/null || true
brew autoupdate start "$BREW_AUTOUPDATE_INTERVAL" --upgrade --cleanup --immediate &>/dev/null
success "Brew autoupdate configured (every 24h)"
