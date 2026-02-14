#!/bin/bash
set -e

DOTFILES="$HOME/dotfiles"

# ============================================================
# Helpers
# ============================================================
info()    { printf "\033[34m→\033[0m %s\n" "$1"; }
success() { printf "\033[32m✓\033[0m %s\n" "$1"; }
warn()    { printf "\033[33m!\033[0m %s\n" "$1"; }

# ============================================================
# 1. Read profile
# ============================================================
if [[ -f "$HOME/.dotfiles-profile" ]]; then
  PROFILE=$(cat "$HOME/.dotfiles-profile")
else
  echo "No profile found. Run setup.sh first."
  exit 1
fi

info "Profile: $PROFILE"

# ============================================================
# 2. Dump brew state
# ============================================================
info "Dumping brew packages..."
mkdir -p "$DOTFILES/brew/$PROFILE"
brew bundle dump --describe --force --file="$DOTFILES/brew/$PROFILE/Brewfile"
success "Updated brew/$PROFILE/Brewfile"

# ============================================================
# 3. Dump Dock pinned apps
# ============================================================
info "Dumping Dock pinned apps..."
mkdir -p "$DOTFILES/dock"
defaults read com.apple.dock persistent-apps 2>/dev/null | \
  python3 -c "
import sys, re, urllib.parse
content = sys.stdin.read()
urls = re.findall(r'\"_CFURLString\"\s*=\s*\"(file://[^\"]+)\"', content)
for url in urls:
    path = urllib.parse.unquote(url.replace('file://', '').rstrip('/'))
    print(path)
" > "$DOTFILES/dock/${PROFILE}.txt"
success "Updated dock/${PROFILE}.txt"

# ============================================================
# 4. Dump npm globals
# ============================================================
info "Dumping npm global packages..."
npm ls -g --depth=0 --json 2>/dev/null | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
deps = data.get('dependencies', {})
# Skip npm itself, corepack, and linked packages
skip = {'npm', 'corepack'}
for name, info in sorted(deps.items()):
    if name not in skip and not info.get('resolved', '').startswith('file:'):
        print(name)
" > "$DOTFILES/npm-globals.txt"
success "Updated npm-globals.txt"

# ============================================================
# 5. Git commit + push
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
  info "Skipped — changes are staged but not committed"
fi
