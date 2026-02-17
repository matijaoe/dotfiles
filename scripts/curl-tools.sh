#!/bin/bash

# Install curl-based tools (bun, deno, claude, etc.)
# Usage: bash scripts/curl-tools.sh

set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

info()    { printf "  \033[34m•\033[0m %s\n" "$1"; }
success() { printf "  \033[32m✓\033[0m %s\n" "$1"; }

install_tool() {
  local cmd="$1"
  local install_cmd="$2"
  if command -v "$cmd" &>/dev/null; then
    success "$cmd"
  else
    info "Installing $cmd..."
    eval "$install_cmd" &>/dev/null
    success "$cmd"
  fi
}

source "$DOTFILES/packages/curl-tools.sh"
