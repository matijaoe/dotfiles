#!/bin/bash

# Install curl-based tools (bun, deno, claude, etc.)
# Usage: bash scripts/curl-tools.sh

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

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
