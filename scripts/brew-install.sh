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

info "Installing from $BREWFILE..."
brew bundle --file="$BREWFILE" || warn "Some packages may have failed — check output above"
success "Done"

# Configure autoupdate
info "Configuring brew autoupdate (every 24h)..."
brew autoupdate stop 2>/dev/null || true
brew autoupdate start "$BREW_AUTOUPDATE_INTERVAL" --upgrade --cleanup --immediate
success "Brew autoupdate configured"
