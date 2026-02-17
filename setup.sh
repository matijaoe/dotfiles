#!/bin/bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/lib/common.sh"

NPM_INSTALLED_FILE=""
PNPM_INSTALLED_FILE=""

cleanup() {
  [[ -n "${NPM_INSTALLED_FILE:-}" && -f "$NPM_INSTALLED_FILE" ]] && rm -f "$NPM_INSTALLED_FILE"
  [[ -n "${PNPM_INSTALLED_FILE:-}" && -f "$PNPM_INSTALLED_FILE" ]] && rm -f "$PNPM_INSTALLED_FILE"
}
trap cleanup EXIT

# ============================================================
# Parse flags
# ============================================================
PROFILE=""

for arg in "$@"; do
  case "$arg" in
    --work)     PROFILE="work" ;;
    --personal) PROFILE="personal" ;;
    *)          echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

# ============================================================
# 1. Xcode Command Line Tools
# ============================================================
section "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  success "Already installed"
else
  info "Installing (this may take a few minutes)..."
  xcode-select --install
  echo "Press any key when the installation is complete..."
  read -n 1 -s
fi

# ============================================================
# 2. Homebrew
# ============================================================
section "Homebrew"
if command_exists brew; then
  success "Already installed"
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Ensure brew is on PATH for this script
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ============================================================
# 3. Zinit
# ============================================================
section "Zinit"
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ -d "$ZINIT_HOME" ]]; then
  success "Already installed"
else
  info "Installing Zinit..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  success "Done"
fi

# ============================================================
# 4. Detect profile
# ============================================================
section "Profile"
if [[ -z "$PROFILE" ]]; then
  PROFILE="$(resolve_profile)"
  if [[ -n "$PROFILE" ]]; then
    info "Using saved profile: $PROFILE"
  else
    echo "Select profile:"
    select PROFILE in "work" "personal"; do
      [[ -n "$PROFILE" ]] && break
    done
  fi
fi
success "Profile: $PROFILE"
echo "$PROFILE" > "$HOME/.dotfiles-profile"

# ============================================================
# 5. Brew bundle
# ============================================================
section "Brew packages"
bash "$DOTFILES/scripts/brew-install.sh" "--$PROFILE"

# ============================================================
# 6. Symlinks
# ============================================================
section "Symlinks"
bash "$DOTFILES/scripts/symlinks.sh" "--$PROFILE"

# ============================================================
# 7. Node (n)
# ============================================================
section "Node"
# n needs N_PREFIX set to install to ~/.n instead of /usr/local
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
mkdir -p "$N_PREFIX"

if command_exists n; then
  if command_exists node; then
    success "Node already installed: $(node --version)"
  else
    info "Installing Node LTS..."
    n lts
    info "Installing Node latest..."
    n latest
  fi
else
  warn "n not found — should be installed via brew in step 5"
fi

# ============================================================
# 8. npm global packages
# ============================================================
section "npm globals"
if command_exists npm && [[ -f "$DOTFILES/packages/npm-globals.txt" ]]; then
  NPM_LIST_READY=true
  NPM_INSTALLED_FILE="$(mktemp)"
  if ! npm ls -g --depth=0 --json 2>/dev/null | python3 -c '
import json, sys
data = json.load(sys.stdin)
for name in sorted(data.get("dependencies", {}).keys()):
    print(name)
' > "$NPM_INSTALLED_FILE"; then
    NPM_LIST_READY=false
    warn "Could not read npm global package list; falling back to per-package checks"
  fi
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    if [[ "$NPM_LIST_READY" == true ]] && grep -Fxq "$pkg" "$NPM_INSTALLED_FILE"; then
      success "$pkg"
    elif npm list -g "$pkg" --depth=0 &>/dev/null; then
      success "$pkg"
    else
      info "Installing $pkg..."
      npm install -g "$pkg" &>/dev/null && success "$pkg" || warn "$pkg (failed)"
    fi
  done < "$DOTFILES/packages/npm-globals.txt"
elif ! command_exists npm; then
  warn "npm not found — install Node first"
else
  warn "npm-globals.txt not found"
fi

# ============================================================
# 9. pnpm global packages
# ============================================================
section "pnpm globals"
if command_exists pnpm && [[ -f "$DOTFILES/packages/pnpm-globals.txt" ]]; then
  # Ensure PNPM_HOME is set up
  export PNPM_HOME="$HOME/Library/pnpm"
  export PATH="$PNPM_HOME:$PATH"
  if [[ ! -d "$PNPM_HOME" ]]; then
    info "Running pnpm setup..."
    pnpm setup &>/dev/null
  fi
  PNPM_LIST_READY=true
  PNPM_INSTALLED_FILE="$(mktemp)"
  if ! pnpm ls -g --depth=-1 --json 2>/dev/null | python3 -c '
import json, sys
data = json.load(sys.stdin)
deps = {}
if isinstance(data, dict):
    deps.update(data.get("dependencies", {}))
elif isinstance(data, list):
    for item in data:
        if isinstance(item, dict):
            deps.update(item.get("dependencies", {}))
for name in sorted(deps.keys()):
    print(name)
' > "$PNPM_INSTALLED_FILE"; then
    PNPM_LIST_READY=false
    warn "Could not read pnpm global package list; falling back to per-package checks"
  fi
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    if [[ "$PNPM_LIST_READY" == true ]] && grep -Fxq "$pkg" "$PNPM_INSTALLED_FILE"; then
      success "$pkg"
    elif pnpm list -g "$pkg" &>/dev/null; then
      success "$pkg"
    else
      info "Installing $pkg..."
      pnpm install -g "$pkg" &>/dev/null && success "$pkg" || warn "$pkg (failed)"
    fi
  done < "$DOTFILES/packages/pnpm-globals.txt"
elif ! command_exists pnpm; then
  warn "pnpm not found — skipping"
else
  warn "pnpm-globals.txt not found"
fi

# ============================================================
# 10. Curl-installed tools (self-updating)
# ============================================================
section "Curl-installed tools"
bash "$DOTFILES/scripts/curl-tools.sh"

# ============================================================
# 11. mise (work profile only)
# ============================================================
section "mise"
if [[ "$PROFILE" == "work" ]] && command_exists mise; then
  info "Installing work tools..."
  mise use --global awscli kubectl sops &>/dev/null
  success "awscli, kubectl, sops"
elif [[ "$PROFILE" == "work" ]]; then
  warn "mise not found — should be installed via brew in step 5"
else
  success "Skipped (not work profile)"
fi

# ============================================================
# 12. macOS defaults
# ============================================================
section "macOS defaults"
if [[ -f "$DOTFILES/scripts/macos-defaults.sh" ]]; then
  bash "$DOTFILES/scripts/macos-defaults.sh" &>/dev/null
  success "Applied — some changes require restart"
else
  warn "scripts/macos-defaults.sh not found"
fi

# ============================================================
# 13. Dock
# ============================================================
section "Dock"
if command_exists dockutil; then
  bash "$DOTFILES/scripts/dock-apply.sh" "--$PROFILE"
else
  warn "dockutil not found — install with: brew install dockutil"
fi

# ============================================================
# Summary
# ============================================================
echo ""
printf "\033[1;32m✓ Setup complete!\033[0m\n"

# Post-setup checks
section "Manual steps"

if ! command_exists op || ! op account list &>/dev/null 2>&1; then
  warn "1Password SSH Agent not configured"
  info "Open 1Password → Settings → Developer → enable SSH Agent"
  info "Sign in to CLI: op signin"
fi

if [[ ! -f "$HOME/.ssh/key-github" ]]; then
  warn "SSH key not found"
  info "Export from 1Password or generate new: ~/.ssh/key-github"
fi

if [[ "$PROFILE" == "work" ]] && ! docker info &>/dev/null; then
  warn "Docker not running"
  info "Open OrbStack to complete setup"
fi

warn "App Store sign-in required"
info "Install apps from $DOTFILES/packages/apps.md"

echo ""
