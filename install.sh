#!/bin/bash

# Bootstrap dotfiles on a fresh Mac
#
# Usage:
#   curl -fsSL matijao.com/dotfiles | bash
#   curl -fsSL raw.githubusercontent.com/matijaoe/dotfiles/main/install.sh | bash
#
# Options:
#   --work       Set up as work machine
#   --personal   Set up as personal machine

set -euo pipefail

DOTFILES_DIR="${DOTFILES:-$HOME/dotfiles}"
DOTFILES_REPO="https://github.com/matijaoe/dotfiles.git"

info()  { printf "\033[34m→\033[0m %s\n" "$1"; }
error() { printf "\033[31m✗\033[0m %s\n" "$1" >&2; }

# macOS only
if [[ "$(uname)" != "Darwin" ]]; then
  error "This script is for macOS only"
  exit 1
fi

# Ensure git works (triggers Xcode CLT prompt on fresh macOS)
if ! command -v git &>/dev/null; then
  info "Xcode Command Line Tools are required"
  xcode-select --install 2>/dev/null || true
  info "Waiting for installation to complete..."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  info "Xcode CLT installed"
fi

# Clone or update dotfiles
if [[ -d "$DOTFILES_DIR/.git" ]]; then
  info "Dotfiles already cloned at $DOTFILES_DIR"
  info "Pulling latest changes..."
  git -C "$DOTFILES_DIR" pull --ff-only 2>/dev/null || true
else
  info "Cloning dotfiles..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# Hand off to setup (reattach stdin to terminal for interactive prompts)
info "Starting setup..."
exec "$DOTFILES_DIR/setup.sh" "$@" </dev/tty
