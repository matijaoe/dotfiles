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
check_profile_conflict "$PROFILE"
show_profile "$PROFILE" "$@"

# Install packages
BREWFILE="$DOTFILES/packages/brew/$PROFILE/Brewfile"
if [[ ! -f "$BREWFILE" ]]; then
  error "No Brewfile found at $BREWFILE"
  exit 1
fi

# Transient output helpers (overwrite current line)
_SPIN=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
_SPIN_IDX=0
clear_line() { printf "\r\033[K"; }
spin_line()  { printf "\r\033[K  \033[2m%s %s\033[0m" "${_SPIN[$_SPIN_IDX]}" "$1"; _SPIN_IDX=$(( (_SPIN_IDX + 1) % ${#_SPIN[@]} )); }

USING=0
INSTALLING=0
UPGRADING=0
PENDING_ACTION=""  # tracks current install/upgrade in progress

# Count Brewfile entries by type
BREW_COUNT=$(grep -c '^brew ' "$BREWFILE" 2>/dev/null) || BREW_COUNT=0
CASK_COUNT=$(grep -c '^cask ' "$BREWFILE" 2>/dev/null) || CASK_COUNT=0
VSCODE_COUNT=$(grep -c '^vscode ' "$BREWFILE" 2>/dev/null) || VSCODE_COUNT=0

# Finish a pending install/upgrade action with a permanent ✓ line
flush_pending() {
  if [[ -n "$PENDING_ACTION" ]]; then
    clear_line
    success "$PENDING_ACTION"
    PENDING_ACTION=""
  fi
}

# Stream brew bundle output for real-time feedback
while IFS= read -r line; do
  if [[ "$line" =~ ^Using[[:space:]](.+) ]]; then
    ((USING++)) || true
    flush_pending
    spin_line "${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^Installing[[:space:]](.+) ]]; then
    ((INSTALLING++)) || true
    flush_pending
    PENDING_ACTION="${BASH_REMATCH[1]}"
    spin_line "Installing ${BASH_REMATCH[1]}..."
  elif [[ "$line" =~ ^Upgrading[[:space:]](.+) ]]; then
    ((UPGRADING++)) || true
    flush_pending
    PENDING_ACTION="${BASH_REMATCH[1]}"
    spin_line "Upgrading ${BASH_REMATCH[1]}..."
  fi
done < <(brew bundle --file="$BREWFILE" 2>&1 || true)

flush_pending
clear_line

# Summary
if [[ "$INSTALLING" -gt 0 || "$UPGRADING" -gt 0 ]]; then
  echo ""
  PARTS=()
  [[ "$INSTALLING" -gt 0 ]] && PARTS+=("$INSTALLING installed")
  [[ "$UPGRADING" -gt 0 ]] && PARTS+=("$UPGRADING upgraded")
  JOIN=$(IFS=,; echo "${PARTS[*]}" | sed 's/,/, /g')
  BREAKDOWN="$BREW_COUNT formulae, $CASK_COUNT casks"
  [[ "$VSCODE_COUNT" -gt 0 ]] && BREAKDOWN+=", $VSCODE_COUNT extensions"
  summary "$JOIN — $BREAKDOWN"
else
  BREAKDOWN="$BREW_COUNT formulae, $CASK_COUNT casks"
  [[ "$VSCODE_COUNT" -gt 0 ]] && BREAKDOWN+=", $VSCODE_COUNT extensions"
  summary "$BREAKDOWN up to date"
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
