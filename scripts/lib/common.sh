#!/bin/bash

# Shared helpers for scripts in this repository.

if [[ -n "${DOTFILES_COMMON_SH_LOADED:-}" ]]; then
  return 0
fi
DOTFILES_COMMON_SH_LOADED=1

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DOTFILES

info()    { printf "  \033[34m•\033[0m %s\n" "$1"; }
success() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn()    { printf "  \033[33m!\033[0m %s\n" "$1"; }
section() { printf "\n\033[1;36m➤ %s\033[0m\n" "$1"; }

resolve_profile() {
  local profile="${1:-}"
  if [[ -z "$profile" && -f "$HOME/.dotfiles-profile" ]]; then
    profile="$(<"$HOME/.dotfiles-profile")"
  fi
  printf "%s" "$profile"
}

require_profile() {
  local script_name="$1"
  local profile
  profile="$(resolve_profile "${2:-}")"

  if [[ -z "$profile" ]]; then
    echo "Usage: $script_name <profile>"
    echo "Or set profile via: echo work > ~/.dotfiles-profile"
    return 1
  fi

  printf "%s" "$profile"
}
