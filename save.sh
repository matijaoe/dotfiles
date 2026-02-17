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

# ============================================================
# 1. Read profile
# ============================================================
PROFILE="$(resolve_profile)"
if [[ -z "$PROFILE" ]]; then
  echo "No profile found. Run setup.sh first."
  exit 1
fi

info "Profile: $PROFILE"

# ============================================================
# 2. Dump brew state
# ============================================================
info "Dumping brew packages..."
mkdir -p "$DOTFILES/packages/brew/$PROFILE"
if command_exists brew; then
  brew bundle dump --describe --force --file="$DOTFILES/packages/brew/$PROFILE/Brewfile"
  success "Updated packages/brew/$PROFILE/Brewfile"
else
  warn "brew not found — skipping Brewfile dump"
fi

# ============================================================
# 3. Dump Dock pinned apps
# ============================================================
info "Dumping Dock pinned apps..."
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
success "Updated packages/dock/${PROFILE}.txt"

# ============================================================
# 4. Dump npm globals
# ============================================================
info "Dumping npm global packages..."
_npm_tmp=$(mktemp)
if command_exists npm && npm ls -g --depth=0 --json 2>/dev/null | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
deps = data.get('dependencies', {})
# Skip npm itself, corepack, and linked packages
skip = {'npm', 'corepack'}
for name, info in sorted(deps.items()):
    if name not in skip and not info.get('resolved', '').startswith('file:'):
        print(name)
" > "$_npm_tmp" 2>/dev/null; then
  mv "$_npm_tmp" "$DOTFILES/packages/npm-globals.txt"
  _npm_tmp=""
  success "Updated packages/npm-globals.txt"
else
  rm -f "$_npm_tmp"
  _npm_tmp=""
  warn "Failed to dump npm globals or npm not found — keeping existing file"
fi

# ============================================================
# 5. Dump pnpm globals
# ============================================================
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
if command_exists pnpm; then
  info "Dumping pnpm global packages..."
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
    success "Updated packages/pnpm-globals.txt"
  else
    rm -f "$_pnpm_tmp"
    _pnpm_tmp=""
    warn "Failed to dump pnpm globals — keeping existing file"
  fi
else
  warn "pnpm not found — skipping pnpm globals dump"
fi

# ============================================================
# 6. Git commit + push
# ============================================================
cd "$DOTFILES"

if [[ -z $(git status --porcelain) ]]; then
  success "Nothing to save — repo is clean"
  exit 0
fi

echo ""
info "Changes detected:"
git status --short
echo ""

read -p "Commit and push? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  git add -A
  git commit -m "save: $(date '+%Y-%m-%d %H:%M')"
  git push
  success "Saved and pushed"
else
  info "Skipped — changes are not committed"
fi
