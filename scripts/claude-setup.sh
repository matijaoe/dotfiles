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
      ((LINKED++)) || true
      ;;
    replaced)
      warn "$name (backed up existing → ${name}.bak)"
      ((REPLACED++)) || true
      ;;
    created)
      success "$name"
      ((CREATED++)) || true
      ;;
  esac
}

section "Claude Code"

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
  printf "\033[32m✓\033[0m %d/%d up to date\n" "$TOTAL" "$TOTAL"
else
  printf "\033[32m✓\033[0m %d created, %d replaced, %d already linked\n" "$CREATED" "$REPLACED" "$LINKED"
fi
