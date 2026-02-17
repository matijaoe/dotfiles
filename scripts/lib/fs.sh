#!/bin/bash

# Shared filesystem helpers for scripts in this repository.

if [[ -n "${DOTFILES_FS_SH_LOADED:-}" ]]; then
  return 0
fi
DOTFILES_FS_SH_LOADED=1

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# symlink_with_backup <src> <dest>
# Sets SYMLINK_RESULT to one of:
# - already_linked
# - created
# - replaced
symlink_with_backup() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    SYMLINK_RESULT="already_linked"
    return 0
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    mv "$dest" "${dest}.bak"
    ln -s "$src" "$dest"
    SYMLINK_RESULT="replaced"
    return 0
  fi

  ln -s "$src" "$dest"
  SYMLINK_RESULT="created"
}
