#!/bin/bash

set -euo pipefail

# Ensure stdin is connected to terminal (needed when piped via curl | bash)
[[ ! -t 0 ]] && exec </dev/tty

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/lib/common.sh"
export DOTFILES_SETUP=1

NPM_INSTALLED_FILE=""
PNPM_INSTALLED_FILE=""
GUM_TMP=""

cleanup() {
  [[ -n "${NPM_INSTALLED_FILE:-}" && -f "$NPM_INSTALLED_FILE" ]] && rm -f "$NPM_INSTALLED_FILE"
  [[ -n "${PNPM_INSTALLED_FILE:-}" && -f "$PNPM_INSTALLED_FILE" ]] && rm -f "$PNPM_INSTALLED_FILE"
  [[ -n "${GUM_TMP:-}" && -d "$GUM_TMP" ]] && rm -rf "$GUM_TMP"
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
# 0. Bootstrap gum (pretty terminal output)
# ============================================================
if ! has_gum; then
  GUM_VERSION="0.17.0"
  GUM_TMP="$(mktemp -d)"
  _arch="$(uname -m)"
  _tarball="gum_${GUM_VERSION}_Darwin_${_arch}.tar.gz"
  _url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/${_tarball}"

  if curl -fsSL "$_url" | tar xz -C "$GUM_TMP" 2>/dev/null; then
    _gum_bin="$(find "$GUM_TMP" -name gum -type f | head -1)"
    if [[ -n "$_gum_bin" ]]; then
      chmod +x "$_gum_bin"
      export PATH="$(dirname "$_gum_bin"):$PATH"
    fi
  fi
  unset _arch _tarball _url _gum_bin

  if ! has_gum; then
    printf "  \033[31m✗\033[0m Failed to bootstrap gum — cannot continue.\n"
    printf "  \033[34m•\033[0m Install manually: brew install gum\n"
    exit 1
  fi
fi

# ============================================================
# 1. Xcode Command Line Tools
# ============================================================
section "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  success "Already installed"
else
  info "Installing (this may take a few minutes)..."
  xcode-select --install 2>/dev/null || true
  gum spin --spinner dot --title "Waiting for Xcode CLT installation..." -- \
    bash -c 'until xcode-select -p &>/dev/null; do sleep 5; done'
  success "Done"
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
# 3. Detect profile
# ============================================================
section "Profile"
if [[ -z "$PROFILE" ]]; then
  PROFILE="$(resolve_profile)"
  if [[ -n "$PROFILE" ]]; then
    info "Using saved profile: $PROFILE"
  else
    info "Select profile:"
    PROFILE=$(choose_one "work" "personal")
  fi
else
  check_profile_conflict "$PROFILE" --saves-profile
fi
printf "  \033[32m✓\033[0m Profile: \033[1;33m%s\033[0m\n" "$PROFILE"
echo "$PROFILE" > "$HOME/.dotfiles-profile"

# ============================================================
# 5. Brew bundle
# ============================================================
bash "$DOTFILES/scripts/brew-install.sh" "--$PROFILE"

# ============================================================
# 6. Symlinks
# ============================================================
bash "$DOTFILES/scripts/symlinks.sh" "--$PROFILE"

# ============================================================
# 7. Cursor (copy-based — Cursor overwrites symlinks on save)
# ============================================================
if command_exists cursor; then
  bash "$DOTFILES/scripts/cursor-setup.sh"
else
  section "Cursor"
  warn "cursor not found — install via brew first"
fi

# ============================================================
# 8. Node (n)
# ============================================================

section "Node"
# n needs N_PREFIX set to install to ~/.n instead of /usr/local
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
mkdir -p "$N_PREFIX"

if command_exists n; then
  CURRENT_VER=$(node --version 2>/dev/null || echo "")
  LTS_VER=$(n --lts 2>/dev/null || echo "")
  LATEST_VER=$(n --latest 2>/dev/null || echo "")

  if [[ -z "$CURRENT_VER" ]]; then
    gum spin --spinner dot --title "Installing Node LTS..." -- n lts
    gum spin --spinner dot --title "Installing Node latest..." -- n latest
    n lts &>/dev/null
    CURRENT_VER=$(node --version)
    LTS_VER=$(n --lts)
    LATEST_VER=$(n --latest)
  fi

  # Mark which version is active with bold + arrow
  _node_line() {
    local ver="$1" tag="$2" is_default="$3"
    if [[ "$is_default" == "true" ]]; then
      printf "  \033[32m✓\033[0m \033[1m%s\033[0m (%s) ◂ default\n" "$ver" "$tag"
    else
      printf "  \033[32m✓\033[0m %s (%s)\n" "$ver" "$tag"
    fi
  }

  if [[ "$CURRENT_VER" == "v$LTS_VER" ]]; then
    _node_line "v$LTS_VER" "lts" "true"
    _node_line "v$LATEST_VER" "latest" "false"
  elif [[ "$CURRENT_VER" == "v$LATEST_VER" ]]; then
    _node_line "v$LTS_VER" "lts" "false"
    _node_line "v$LATEST_VER" "latest" "true"
  else
    _node_line "v$LTS_VER" "lts" "false"
    _node_line "v$LATEST_VER" "latest" "false"
    _node_line "$CURRENT_VER" "custom" "true"
  fi
else
  warn "n not found — should be installed via brew in step 5"
fi

# ============================================================
# 9. npm global packages
# ============================================================
section "npm globals"
NPM_TOTAL=0
NPM_INSTALLED=0
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
    ((NPM_TOTAL++)) || true
    if [[ "$NPM_LIST_READY" == true ]] && grep -Fxq "$pkg" "$NPM_INSTALLED_FILE"; then
      success "$pkg"
    elif npm list -g "$pkg" --depth=0 &>/dev/null; then
      success "$pkg"
    else
      info "Installing $pkg..."
      if npm install -g "$pkg" &>/dev/null; then
        success "$pkg"
        ((NPM_INSTALLED++)) || true
      else
        warn "$pkg (failed)"
      fi
    fi
  done < "$DOTFILES/packages/npm-globals.txt"
  if [[ "$NPM_TOTAL" -eq 0 ]]; then
    summary "No packages configured"
  else
    echo ""
    if [[ "$NPM_INSTALLED" -eq 0 ]]; then
      summary "$NPM_TOTAL packages up to date"
    else
      summary "$NPM_INSTALLED installed, $((NPM_TOTAL - NPM_INSTALLED)) already up to date"
    fi
  fi
elif ! command_exists npm; then
  warn "npm not found — install Node first"
else
  warn "npm-globals.txt not found"
fi

# ============================================================
# 10. pnpm global packages
# ============================================================
section "pnpm globals"
PNPM_TOTAL=0
PNPM_INSTALLED=0
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
    ((PNPM_TOTAL++)) || true
    if [[ "$PNPM_LIST_READY" == true ]] && grep -Fxq "$pkg" "$PNPM_INSTALLED_FILE"; then
      success "$pkg"
    elif pnpm list -g "$pkg" &>/dev/null; then
      success "$pkg"
    else
      info "Installing $pkg..."
      if pnpm install -g "$pkg" &>/dev/null; then
        success "$pkg"
        ((PNPM_INSTALLED++)) || true
      else
        warn "$pkg (failed)"
      fi
    fi
  done < "$DOTFILES/packages/pnpm-globals.txt"
  if [[ "$PNPM_TOTAL" -eq 0 ]]; then
    summary "No packages configured"
  else
    echo ""
    if [[ "$PNPM_INSTALLED" -eq 0 ]]; then
      summary "$PNPM_TOTAL packages up to date"
    else
      summary "$PNPM_INSTALLED installed, $((PNPM_TOTAL - PNPM_INSTALLED)) already up to date"
    fi
  fi
elif ! command_exists pnpm; then
  warn "pnpm not found — skipping"
else
  warn "pnpm-globals.txt not found"
fi

# ============================================================
# 11. Curl-installed tools (self-updating)
# ============================================================
bash "$DOTFILES/scripts/curl-tools.sh"

# ============================================================
# 12. mise (work profile only)
# ============================================================
section "mise"
if [[ "$PROFILE" == "work" ]] && command_exists mise; then
  gum spin --spinner dot --title "Installing work tools..." -- \
    mise use --global awscli kubectl sops
  success "awscli, kubectl, sops"
elif [[ "$PROFILE" == "work" ]]; then
  warn "mise not found — should be installed via brew in step 5"
else
  success "Skipped (not work profile)"
fi

# ============================================================
# 13. macOS defaults
# ============================================================
section "macOS defaults"
if [[ -f "$DOTFILES/scripts/macos-defaults.sh" ]]; then
  gum spin --spinner dot --title "Applying macOS defaults..." -- \
    bash "$DOTFILES/scripts/macos-defaults.sh"
  success "Applied — some changes require restart"
else
  warn "scripts/macos-defaults.sh not found"
fi

# ============================================================
# 14. Dock
# ============================================================
if command_exists dockutil; then
  bash "$DOTFILES/scripts/dock-apply.sh" "--$PROFILE"
else
  warn "dockutil not found — install with: brew install dockutil"
fi

# ============================================================
# Summary
# ============================================================
echo ""
gum style --bold --foreground 2 --border rounded --border-foreground 2 --padding "0 2" "✓ Setup complete!"

# Post-setup checks
MANUAL_STEPS=()

if ! command_exists op || ! op account list &>/dev/null 2>&1; then
  MANUAL_STEPS+=("1Password SSH Agent — Settings → Developer → enable SSH Agent")
fi

if [[ ! -f "$HOME/.ssh/key-github" ]]; then
  MANUAL_STEPS+=("SSH key — export from 1Password or generate ~/.ssh/key-github")
fi

if [[ "$PROFILE" == "work" ]] && ! docker info &>/dev/null; then
  MANUAL_STEPS+=("Docker — open OrbStack to complete setup")
fi

MANUAL_STEPS+=("App Store — sign in and install apps from packages/apps.md")

if [[ ${#MANUAL_STEPS[@]} -gt 0 ]]; then
  echo ""
  gum style --bold --foreground 214 "➤ Manual steps"
  for step in "${MANUAL_STEPS[@]}"; do
    warn "$step"
  done
fi

echo ""
