#!/bin/bash

# Install curl-based tools (bun, deno, claude, etc.)
# Usage: bash scripts/curl-tools.sh

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

section "Curl-installed tools"

CURL_TOTAL=0
CURL_INSTALLED=0

install_tool() {
  local cmd="$1"
  local install_cmd="$2"
  ((CURL_TOTAL++)) || true
  if command -v "$cmd" &>/dev/null; then
    success "$cmd"
  else
    info "Installing $cmd..."
    eval "$install_cmd" &>/dev/null
    success "$cmd"
    ((CURL_INSTALLED++)) || true
  fi
}

source "$DOTFILES/packages/curl-tools.sh"

echo ""
if [[ "$CURL_INSTALLED" -eq 0 ]]; then
  summary "$CURL_TOTAL tools up to date"
else
  summary "$CURL_INSTALLED installed, $((CURL_TOTAL - CURL_INSTALLED)) already up to date"
fi
