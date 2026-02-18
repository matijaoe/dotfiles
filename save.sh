#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/lib/common.sh"

_npm_tmp=""
_pnpm_tmp=""

cleanup() {
  [[ -n "${_npm_tmp:-}" && -f "$_npm_tmp" ]] && rm -f "$_npm_tmp"
  [[ -n "${_pnpm_tmp:-}" && -f "$_pnpm_tmp" ]] && rm -f "$_pnpm_tmp"
}
trap cleanup EXIT

echo ""
gum style --bold "dots save"
echo ""

# ============================================================
# 1. Read profile
# ============================================================
PROFILE="$(resolve_profile)"
if [[ -z "$PROFILE" ]]; then
  error "No profile found. Run setup.sh first."
  exit 1
fi

printf "  \033[32m✓\033[0m Profile: \033[1;33m%s\033[0m\n" "$PROFILE"
echo ""

# ============================================================
# 2. Snapshot current state
# ============================================================
info "Snapshotting..."

# Brew
mkdir -p "$DOTFILES/packages/brew/$PROFILE"
if command_exists brew; then
  gum spin --spinner dot --title "Brew packages..." -- \
    brew bundle dump --describe --no-vscode --force --file="$DOTFILES/packages/brew/$PROFILE/Brewfile"
  success "Brewfile"
else
  warn "brew not found — skipping"
fi

# Dock
mkdir -p "$DOTFILES/packages/dock"
defaults read com.apple.dock persistent-apps 2>/dev/null | \
  python3 -c "
import sys, re, urllib.parse
content = sys.stdin.read()
urls = re.findall(r'\"_CFURLString\"\s*=\s*\"(file://[^\"]+)\"', content)
for url in urls:
    path = urllib.parse.unquote(url.replace('file://', '').rstrip('/'))
    print(path)
" > "$DOTFILES/packages/dock/${PROFILE}.txt"
success "Dock"

# npm globals
_npm_tmp=$(mktemp)
if command_exists npm && npm ls -g --depth=0 --json 2>/dev/null | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
deps = data.get('dependencies', {})
skip = {'npm', 'corepack'}
for name, info in sorted(deps.items()):
    if name not in skip and not info.get('resolved', '').startswith('file:'):
        print(name)
" > "$_npm_tmp" 2>/dev/null; then
  mv "$_npm_tmp" "$DOTFILES/packages/npm-globals.txt"
  _npm_tmp=""
  success "npm globals"
else
  rm -f "$_npm_tmp"
  _npm_tmp=""
  warn "npm globals — failed to dump, keeping existing"
fi

# pnpm globals
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
if command_exists pnpm; then
  _pnpm_tmp=$(mktemp)
  if pnpm ls -g --json 2>/dev/null | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
for store in data:
    deps = store.get('dependencies', {})
    for name in sorted(deps.keys()):
        print(name)
" > "$_pnpm_tmp" 2>/dev/null; then
    mv "$_pnpm_tmp" "$DOTFILES/packages/pnpm-globals.txt"
    _pnpm_tmp=""
    success "pnpm globals"
  else
    rm -f "$_pnpm_tmp"
    _pnpm_tmp=""
    warn "pnpm globals — failed to dump, keeping existing"
  fi
fi

# ============================================================
# 3. Git commit + push
# ============================================================
cd "$DOTFILES"

if [[ -z $(git status --porcelain) ]]; then
  echo ""
  summary "Nothing to save — repo is clean"
  exit 0
fi

echo ""
info "Changes detected:"
git status --short
echo ""

if confirm "Commit and push?"; then
  git add -A
  git commit -m "save: $(date '+%Y-%m-%d %H:%M')"
  if ! git push; then
    error "Push failed"
    exit 1
  fi
  summary "Saved and pushed"
else
  warn "Skipped — changes not committed"
fi
