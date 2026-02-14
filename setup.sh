#!/bin/bash

DOTFILES="$HOME/dotfiles"
BREW_AUTOUPDATE_INTERVAL=86400  # 24 hours in seconds

# ============================================================
# Helpers
# ============================================================
info()    { printf "\033[34m→\033[0m %s\n" "$1"; }
success() { printf "\033[32m✓\033[0m %s\n" "$1"; }
warn()    { printf "\033[33m!\033[0m %s\n" "$1"; }
step()    { printf "\n\033[1;35m%s\033[0m\n" "$1"; }

command_exists() { command -v "$1" &>/dev/null; }

# ============================================================
# Parse flags
# ============================================================
PROFILE=""
APPLY_MACOS=false

for arg in "$@"; do
  case "$arg" in
    --work)     PROFILE="work" ;;
    --personal) PROFILE="personal" ;;
    --macos)    APPLY_MACOS=true ;;
    *)          echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

# ============================================================
# 1. Xcode Command Line Tools
# ============================================================
step "1. Xcode Command Line Tools"
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
step "2. Homebrew"
if command_exists brew; then
  success "Already installed"
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Ensure brew is on PATH for this script
eval "$(/opt/homebrew/bin/brew shellenv)"

# ============================================================
# 3. Zinit
# ============================================================
step "3. Zinit"
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
step "4. Profile"
if [[ -z "$PROFILE" ]]; then
  if [[ -f "$HOME/.dotfiles-profile" ]]; then
    PROFILE=$(cat "$HOME/.dotfiles-profile")
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
step "5. Brew packages"
BREWFILE="$DOTFILES/brew/$PROFILE/Brewfile"
if [[ ! -f "$BREWFILE" ]]; then
  warn "No Brewfile found at $BREWFILE — skipping"
else
  info "Installing from $BREWFILE..."
  brew bundle --file="$BREWFILE" || warn "Some packages may have failed — check output above"
  success "Done"
fi

# Configure brew autoupdate (every 24h)
if command_exists brew; then
  info "Configuring brew autoupdate (every 24h)..."
  # Stop existing autoupdate if running
  brew autoupdate stop 2>/dev/null || true
  # Start: upgrade + cleanup every 24h (86400 seconds)
  brew autoupdate start "$BREW_AUTOUPDATE_INTERVAL" --upgrade --cleanup --immediate
  success "Brew autoupdate configured"
fi

# ============================================================
# 6. Symlinks
# ============================================================
step "6. Symlinks"

link_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      success "Already linked: $dest"
      return
    fi
    mv "$dest" "${dest}.bak"
    warn "Backed up: $dest → ${dest}.bak"
  fi

  ln -s "$src" "$dest"
  success "Linked: $dest → $src"
}

link_file "$DOTFILES/shell/.zshrc"              "$HOME/.zshrc"
link_file "$DOTFILES/shell/omz-aliases"         "$HOME/.local/share/zinit/plugins/omz-aliases"
link_file "$DOTFILES/config/starship.toml"      "$HOME/.config/starship.toml"
link_file "$DOTFILES/config/ghostty/config"     "$HOME/.config/ghostty/config"
link_file "$DOTFILES/config/micro/settings.json" "$HOME/.config/micro/settings.json"
link_file "$DOTFILES/config/micro/bindings.json" "$HOME/.config/micro/bindings.json"
link_file "$DOTFILES/config/gh/config.yml"      "$HOME/.config/gh/config.yml"
link_file "$DOTFILES/config/gh-dash/config.yml" "$HOME/.config/gh-dash/config.yml"
link_file "$DOTFILES/git/.gitconfig"            "$HOME/.gitconfig"
link_file "$DOTFILES/git/ignore"                "$HOME/.config/git/ignore"
link_file "$DOTFILES/ssh/config.$PROFILE"       "$HOME/.ssh/config"

# ============================================================
# 7. Node (n)
# ============================================================
step "7. Node"
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
step "8. npm globals"
if command_exists npm && [[ -f "$DOTFILES/npm-globals.txt" ]]; then
  info "Installing npm global packages..."
  xargs npm install -g < "$DOTFILES/npm-globals.txt"
  success "Done"
elif ! command_exists npm; then
  warn "npm not found — install Node first"
else
  warn "npm-globals.txt not found"
fi

# ============================================================
# 9. Curl-installed tools (self-updating)
# ============================================================
step "9. Curl-installed tools"

# Bun
if command_exists bun; then
  success "Bun already installed: $(bun --version)"
else
  info "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  success "Bun installed (available in new terminal)"
fi

# Deno
if command_exists deno; then
  success "Deno already installed: $(deno --version | head -1)"
else
  info "Installing Deno..."
  curl -fsSL https://deno.land/install.sh | sh
  success "Deno installed (available in new terminal)"
fi

# Claude Code
if command_exists claude; then
  success "Claude Code already installed"
else
  info "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  success "Claude Code installed (available in new terminal)"
fi

# OpenCode
if command_exists opencode; then
  success "OpenCode already installed"
else
  info "Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  success "OpenCode installed (available in new terminal)"
fi

# Amp Code
if command_exists amp; then
  success "Amp Code already installed"
else
  info "Installing Amp Code..."
  curl -fsSL https://ampcode.com/install.sh | bash
  success "Amp Code installed (available in new terminal)"
fi



# ============================================================
# 10. mise (work profile only)
# ============================================================
step "10. mise"
if [[ "$PROFILE" == "work" ]] && command_exists mise; then
  info "Installing work tools via mise..."
  mise use --global awscli kubectl sops
  success "Done"
elif [[ "$PROFILE" == "work" ]]; then
  warn "mise not found — should be installed via brew in step 5"
else
  success "Skipped (not work profile)"
fi

# ============================================================
# 11. macOS defaults
# ============================================================
if [[ "$APPLY_MACOS" == true ]]; then
  step "11. macOS defaults"
  if [[ -f "$DOTFILES/macos.sh" ]]; then
    info "Applying macOS defaults..."
    bash "$DOTFILES/macos.sh"
    success "Done — some changes require a restart"
  else
    warn "macos.sh not found"
  fi
else
  step "11. macOS defaults (skipped — use --macos to apply)"
fi

# ============================================================
# 12. Dock apps
# ============================================================
step "12. Dock apps"
DOCK_FILE="$DOTFILES/dock/${PROFILE}.txt"
if [[ -f "$DOCK_FILE" ]]; then
  if command_exists dockutil; then
    info "Applying Dock layout for $PROFILE..."
    bash "$DOTFILES/dock/apply.sh" "$PROFILE"
    success "Done"
  else
    warn "dockutil not found — install with: brew install dockutil"
  fi
else
  info "No Dock config for $PROFILE — skipping"
fi

# ============================================================
# Summary
# ============================================================
step "Setup complete!"
echo ""

# Post-setup checks
MANUAL_STEPS=()

if ! command_exists op || ! op account list &>/dev/null 2>&1; then
  MANUAL_STEPS+=("Open 1Password → Settings → Developer → enable SSH Agent")
  MANUAL_STEPS+=("Sign in to 1Password CLI: op signin")
fi

if [[ ! -f "$HOME/.ssh/key-github" ]]; then
  MANUAL_STEPS+=("Set up SSH key: export from 1Password or generate new (~/.ssh/key-github)")
fi

if [[ "$PROFILE" == "work" ]] && ! docker info &>/dev/null; then
  MANUAL_STEPS+=("Open OrbStack to complete Docker setup")
fi

MANUAL_STEPS+=("Sign in to App Store for manual app installs (see apps.md)")

if [[ ${#MANUAL_STEPS[@]} -gt 0 ]]; then
  echo "Manual steps:"
  for i in "${!MANUAL_STEPS[@]}"; do
    echo "  $((i+1)). ${MANUAL_STEPS[$i]}"
  done
  echo ""
fi
