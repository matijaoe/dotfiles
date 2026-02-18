#!/bin/bash

# Restore Cursor settings and keybindings from dotfiles.
# Not symlinked — Cursor overwrites symlinks on save, so files are copied instead.
# Extensions are tracked via the Brewfile and restored by brew bundle.
# Usage: bash scripts/cursor-setup.sh

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

section "Cursor"

if ! command_exists cursor; then
  error "cursor not found"
  info "Install with: brew install --cask cursor"
  exit 1
fi

CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
mkdir -p "$CURSOR_USER"

# Settings & keybindings (copied, not symlinked — Cursor breaks symlinks on save)
info "Copying settings..."
COPIED=0
for f in settings.json keybindings.json; do
  if [[ -f "$DOTFILES/config/cursor/$f" ]]; then
    cp "$DOTFILES/config/cursor/$f" "$CURSOR_USER/$f"
    success "$f"
    ((COPIED++)) || true
  else
    warn "$f not found in dotfiles"
  fi
done

echo ""
if [[ "$COPIED" -gt 0 ]]; then
  summary "$COPIED files applied"
fi
if [[ "${DOTFILES_SETUP:-}" != "1" ]]; then
  printf "  \033[34m•\033[0m Extensions managed via Brewfile — run \033[1mdots run brew\033[0m to install\n"
fi
