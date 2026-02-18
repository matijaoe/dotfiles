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
# 4. Brew bundle
# ============================================================
bash "$DOTFILES/scripts/brew-install.sh" "--$PROFILE"

# ============================================================
# 5. Mac App Store (personal)
# ============================================================
bash "$DOTFILES/scripts/mas-install.sh" "--$PROFILE"

# ============================================================
# 6. Symlinks
# ============================================================
bash "$DOTFILES/scripts/symlinks.sh" "--$PROFILE"

# ============================================================
# 7. Antidote — bootstrap plugin bundle
# ============================================================
section "Antidote plugins"
if [[ -f /opt/homebrew/opt/antidote/share/antidote/antidote.zsh && -f "$HOME/.zsh_plugins.txt" ]]; then
  rm -f "$HOME/.zsh_plugins.zsh"
  gum spin --spinner dot --title "Bundling zsh plugins..." -- \
    zsh -c 'source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh && antidote bundle < "$HOME/.zsh_plugins.txt" > "$HOME/.zsh_plugins.zsh"'
  if [[ -s "$HOME/.zsh_plugins.zsh" ]]; then
    success "Bundle generated"
  else
    warn "Bundle generation failed — will retry on next shell open"
  fi
else
  warn "antidote not found — should be installed via brew in step 4"
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
  # Always ensure latest and LTS are installed; activate LTS last so it becomes default
  gum spin --spinner dot --title "Installing Node latest..." -- n latest
  gum spin --spinner dot --title "Installing Node LTS..." -- n lts

  LTS_VER=$(n --lts 2>/dev/null || echo "?")
  LATEST_VER=$(n --latest 2>/dev/null || echo "?")

  printf "  \033[32m✓\033[0m \033[1mv%s\033[0m (lts) ◂ active\n" "$LTS_VER"
  printf "  \033[32m✓\033[0m v%s (latest)\n" "$LATEST_VER"
else
  warn "n not found — should be installed via brew in step 4"
fi

# Enable corepack (ships with Node — manages pnpm & yarn; npm manages itself)
if command_exists npm; then
  npm install --global corepack@latest &>/dev/null
  corepack enable &>/dev/null
  corepack prepare pnpm@latest --activate &>/dev/null
  corepack prepare yarn@stable --activate &>/dev/null
  success "corepack enabled ($(corepack --version 2>/dev/null || echo '?')) — pnpm + yarn pinned"
else
  warn "corepack not found — requires Node"
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
  # Ensure PNPM_HOME exists (.zshrc already exports the env vars)
  export PNPM_HOME="$HOME/Library/pnpm"
  export PATH="$PNPM_HOME:$PATH"
  mkdir -p "$PNPM_HOME"
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
  warn "mise not found — should be installed via brew in step 4"
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

if [[ "$PROFILE" == "work" ]] && ! docker info &>/dev/null; then
  MANUAL_STEPS+=("Docker — open OrbStack to complete setup")
fi

if [[ "$PROFILE" == "personal" ]]; then
  MANUAL_STEPS+=("App Store — sign in to install MAS apps: dots run mas")
fi

if [[ ${#MANUAL_STEPS[@]} -gt 0 ]]; then
  echo ""
  gum style --bold --foreground 214 "➤ Manual steps"
  for step in "${MANUAL_STEPS[@]}"; do
    warn "$step"
  done
fi

echo ""
