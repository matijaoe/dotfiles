#!/bin/bash

# Set up Claude Code configuration (settings, agents, statusline, etc.)
# Usage: bash scripts/claude-setup.sh

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fs.sh"
CLAUDE_SRC="$DOTFILES/config/claude"
CLAUDE_DEST="$HOME/.claude"

LINKED=0
CREATED=0
REPLACED=0

link_file() {
  local src="$1"
  local dest="$2"
  local name="$(basename "$dest")"

  # Check if this would override an existing non-symlinked file
  if [[ -e "$dest" && ! -L "$dest" ]] || [[ -L "$dest" && "$(readlink "$dest")" != "$src" ]]; then
    if ! confirm "$name exists and differs — override?"; then
      info "$name (skipped)"
      return
    fi
  fi

  symlink_with_backup "$src" "$dest"
  case "$SYMLINK_RESULT" in
    already_linked)
      success "$name"
      ((LINKED++)) || true
      ;;
    replaced)
      warn "$name (backed up → ${name}.bak)"
      ((REPLACED++)) || true
      ;;
    created)
      success "$name"
      ((CREATED++)) || true
      ;;
  esac
}

section "Claude Code"
info "Symlinking configs..."

# Settings
link_file "$CLAUDE_SRC/settings.json" "$CLAUDE_DEST/settings.json"

# CLAUDE.md
link_file "$CLAUDE_SRC/CLAUDE.md" "$CLAUDE_DEST/CLAUDE.md"

# Statusline
link_file "$CLAUDE_SRC/statusline-command.py" "$CLAUDE_DEST/statusline-command.py"

# Agents
mkdir -p "$CLAUDE_DEST/agents"
for agent in "$CLAUDE_SRC/agents/"*.md; do
  [[ -f "$agent" ]] || continue
  link_file "$agent" "$CLAUDE_DEST/agents/$(basename "$agent")"
done

# Skills
link_file "$CLAUDE_SRC/skills" "$CLAUDE_DEST/skills"

echo ""
TOTAL=$((LINKED + CREATED + REPLACED))
if [[ "$CREATED" -eq 0 && "$REPLACED" -eq 0 ]]; then
  summary "$TOTAL/$TOTAL up to date"
else
  summary "$CREATED created, $REPLACED replaced, $LINKED already linked"
fi
