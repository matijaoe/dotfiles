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

# Spinner characters — each "Using" line advances the spinner
_SPIN=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
_SPIN_IDX=0

USING=0
INSTALLING=0
UPGRADING=0

# Stream brew bundle output for real-time feedback
while IFS= read -r line; do
  if [[ "$line" =~ ^Using[[:space:]](.+) ]]; then
    ((USING++)) || true
    # Transient line: show spinner + package name, overwrites itself
    printf "\r\033[K  \033[2m%s %s\033[0m" "${_SPIN[$_SPIN_IDX]}" "${BASH_REMATCH[1]}"
    _SPIN_IDX=$(( (_SPIN_IDX + 1) % ${#_SPIN[@]} ))
  elif [[ "$line" =~ ^Installing[[:space:]](.+) ]]; then
    ((INSTALLING++)) || true
    # Clear transient spinner line before printing permanent output
    printf "\r\033[K"
    info "Installing ${BASH_REMATCH[1]}..."
  elif [[ "$line" =~ ^Upgrading[[:space:]](.+) ]]; then
    ((UPGRADING++)) || true
    printf "\r\033[K"
    info "Upgrading ${BASH_REMATCH[1]}..."
  fi
done < <(brew bundle --file="$BREWFILE" 2>&1 || true)

# Clear any remaining spinner line
printf "\r\033[K"

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
  gum spin --spinner dot --title "Configuring autoupdate (every ${HOURS}h)..." -- \
    brew autoupdate start "$BREW_AUTOUPDATE_INTERVAL" --upgrade --cleanup
  success "Autoupdate configured"
fi
