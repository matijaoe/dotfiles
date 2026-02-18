#!/bin/bash

# Install Mac App Store apps (personal profile only).
# Usage: bash scripts/mas-install.sh [--work|--personal]

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

section "Mac App Store apps"

PROFILE="$(require_profile "$@")"
check_profile_conflict "$PROFILE"
show_profile "$PROFILE" "$@"

if [[ "$PROFILE" != "personal" ]]; then
  success "Skipped (not personal profile)"
  exit 0
fi

if ! command_exists mas; then
  warn "mas not found — install with: brew install mas"
  exit 0
fi

if ! mas account &>/dev/null; then
  warn "Not signed in to App Store — sign in and run: dots run mas"
  exit 0
fi

MAS_FILE="$DOTFILES/packages/mas/personal.txt"
if [[ ! -f "$MAS_FILE" ]]; then
  warn "No app list at packages/mas/personal.txt"
  exit 0
fi

TOTAL=0
INSTALLED=0
MAS_INSTALLED="$(mas list 2>/dev/null)"

while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  app_id="${line%% *}"
  if [[ "$line" == *"# "* ]]; then
    app_name="${line##*# }"
  else
    app_name="$app_id"
  fi
  ((TOTAL++)) || true
  if echo "$MAS_INSTALLED" | grep -q "^$app_id "; then
    success "$app_name"
  else
    if gum spin --spinner dot --title "Installing $app_name..." -- mas install "$app_id"; then
      success "$app_name"
      ((INSTALLED++)) || true
    else
      warn "$app_name (failed)"
    fi
  fi
done < "$MAS_FILE"

echo ""
if [[ "$TOTAL" -eq 0 ]]; then
  summary "No apps configured — add IDs to packages/mas/personal.txt"
elif [[ "$INSTALLED" -eq 0 ]]; then
  summary "$TOTAL apps up to date"
else
  summary "$INSTALLED installed, $((TOTAL - INSTALLED)) already up to date"
fi
