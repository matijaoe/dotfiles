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
error()   { printf "  \033[31m✗\033[0m %s\n" "$1"; }
section() { printf "\n\033[1;36m➤ %s\033[0m\n" "$1"; }

command_exists() { command -v "$1" &>/dev/null; }

resolve_profile() {
  local profile=""
  for arg in "$@"; do
    case "$arg" in
      --work)     profile="work" ;;
      --personal) profile="personal" ;;
    esac
  done
  if [[ -z "$profile" && -f "$HOME/.dotfiles-profile" ]]; then
    profile="$(<"$HOME/.dotfiles-profile")"
  fi
  printf "%s" "$profile"
}

require_profile() {
  local profile
  profile="$(resolve_profile "$@")"

  if [[ -z "$profile" ]]; then
    echo "No profile set. Use --work or --personal, or run: echo work > ~/.dotfiles-profile" >&2
    return 1
  fi

  printf "%s" "$profile"
}
