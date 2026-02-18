#!/bin/bash

# Install Homebrew packages from Brewfile and configure autoupdate.
# Usage: bash scripts/brew-install.sh [--work|--personal]
# Example: bash scripts/brew-install.sh --work

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
BREW_AUTOUPDATE_INTERVAL=86400  # 24 hours in seconds

section "Brew packages"

# Resolve profile
PROFILE="$(require_profile "$@")"

# Install packages
BREWFILE="$DOTFILES/packages/brew/$PROFILE/Brewfile"
if [[ ! -f "$BREWFILE" ]]; then
  warn "No Brewfile found at $BREWFILE"
  exit 1
fi

# Transient output helpers (overwrite current line)
_SPIN=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
_SPIN_IDX=0
clear_line() { printf "\r\033[K"; }
dim_line()   { printf "\r\033[K  \033[2m%s\033[0m" "$1"; }

USING=0
INSTALLING=0
UPGRADING=0

# Count Brewfile entries by type
BREW_COUNT=$(grep -c '^brew ' "$BREWFILE" 2>/dev/null || echo 0)
CASK_COUNT=$(grep -c '^cask ' "$BREWFILE" 2>/dev/null || echo 0)
VSCODE_COUNT=$(grep -c '^vscode ' "$BREWFILE" 2>/dev/null || echo 0)

# Stream brew bundle output for real-time feedback
while IFS= read -r line; do
  if [[ "$line" =~ ^Using[[:space:]](.+) ]]; then
    ((USING++)) || true
    dim_line "${_SPIN[$_SPIN_IDX]} ${BASH_REMATCH[1]}"
    _SPIN_IDX=$(( (_SPIN_IDX + 1) % ${#_SPIN[@]} ))
  elif [[ "$line" =~ ^Installing[[:space:]](.+) ]]; then
    ((INSTALLING++)) || true
    clear_line
    info "Installing ${BASH_REMATCH[1]}..."
  elif [[ "$line" =~ ^Upgrading[[:space:]](.+) ]]; then
    ((UPGRADING++)) || true
    clear_line
    info "Upgrading ${BASH_REMATCH[1]}..."
  fi
done < <(brew bundle --file="$BREWFILE" 2>&1 || true)

clear_line

PARTS=()
[[ "$INSTALLING" -gt 0 ]] && PARTS+=("$INSTALLING installed")
[[ "$UPGRADING" -gt 0 ]] && PARTS+=("$UPGRADING upgraded")
PARTS+=("$BREW_COUNT formulae, $CASK_COUNT casks, $VSCODE_COUNT extensions up to date")
success "$(IFS='; '; echo "${PARTS[*]}")"

# Configure autoupdate
HOURS=$((BREW_AUTOUPDATE_INTERVAL / 3600))
if brew autoupdate status 2>/dev/null | grep -q "installed and running"; then
  success "Autoupdate running (every ${HOURS}h)"
else
  gum spin --spinner dot --title "Configuring autoupdate (every ${HOURS}h)..." -- \
    brew autoupdate start "$BREW_AUTOUPDATE_INTERVAL" --upgrade --cleanup
  success "Autoupdate configured"
fi
