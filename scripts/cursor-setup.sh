#!/bin/bash

# Restore Cursor settings and keybindings from dotfiles.
# Not symlinked — Cursor overwrites symlinks on save, so files are copied instead.
# Extensions are tracked via the Brewfile and restored by brew bundle.
# Usage: bash scripts/cursor-setup.sh [-y]
#   -y  Override all differing files without prompting (still shows diffs and creates backups)

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

section "Cursor"

# ============================================================
# Parse flags
# ============================================================
FORCE=0
for arg in "$@"; do
  case "$arg" in
    -y) FORCE=1 ;;
  esac
done

if ! command_exists cursor; then
  error "cursor not found"
  info "Install with: brew install --cask cursor"
  exit 1
fi

CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
BACKUP_DIR="$CURSOR_USER/backups"
mkdir -p "$CURSOR_USER"

COPIED=0

# ============================================================
# Apply a single config file with diff check
# ============================================================
apply_file() {
  local filename="$1"
  local src="$DOTFILES/config/cursor/$filename"
  local dst="$CURSOR_USER/$filename"

  if [[ ! -f "$src" ]]; then
    warn "$filename not found in dotfiles"
    return
  fi

  # No existing file — just copy
  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    success "$filename (new)"
    ((COPIED++)) || true
    return
  fi

  # Semantic diff via jq if available, else plain diff
  local diff_output=""
  if command_exists jq; then
    diff_output=$(diff -u <(jq --sort-keys . "$dst") <(jq --sort-keys . "$src") 2>&1) || true
  else
    diff_output=$(diff -u "$dst" "$src" 2>&1) || true
  fi

  if [[ -z "$diff_output" ]]; then
    success "$filename (up to date)"
    return
  fi

  # Check if live has anything that would be lost
  # '-' lines = in live but not in dotfiles; '+' lines = additive (no risk)
  local lost_lines
  lost_lines=$(echo "$diff_output" | grep '^-[^-]' || true)

  if [[ -z "$lost_lines" ]]; then
    # Purely additive — dotfiles just has more, nothing lost from live
    cp "$src" "$dst"
    success "$filename (updated)"
    ((COPIED++)) || true
    return
  fi

  # Live has data that would be lost — show it and ask
  local lost_count
  lost_count=$(echo "$lost_lines" | wc -l | tr -d ' ')

  info "$filename: $lost_count line(s) in live would be lost:"
  if [[ "$lost_count" -gt 30 ]]; then
    echo "$lost_lines" | head -30
    printf "  \033[2m... and %d more lines\033[0m\n" "$((lost_count - 30))"
  else
    echo "$lost_lines"
  fi
  echo ""

  local do_copy=0
  if [[ "$FORCE" -eq 1 ]]; then
    do_copy=1
  else
    confirm "Override $filename? (live changes will be lost)" && do_copy=1 || true
  fi

  if [[ "$do_copy" -eq 1 ]]; then
    local ts
    ts=$(date +%Y%m%dT%H%M%S)
    mkdir -p "$BACKUP_DIR"
    local backup_name="${filename%.json}-$ts.json"
    cp "$dst" "$BACKUP_DIR/$backup_name"
    info "Backed up to backups/$backup_name"
    cp "$src" "$dst"
    success "$filename (overridden)"
    ((COPIED++)) || true
  else
    warn "$filename skipped"
  fi
}

# ============================================================
# Apply settings and keybindings
# ============================================================
apply_file "settings.json"
apply_file "keybindings.json"

echo ""
if [[ "$COPIED" -gt 0 ]]; then
  summary "$COPIED files applied"
fi
if [[ "${DOTFILES_SETUP:-}" != "1" ]]; then
  printf "  \033[34m•\033[0m Extensions managed via Brewfile — run \033[1mdots run brew\033[0m to install\n"
fi
