# ============================================================
# Completions
# ============================================================
fpath=(~/.config/shell/completions $fpath)

# ============================================================
# Antidote plugin manager
# ============================================================
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  (
    source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
    antidote bundle <${zsh_plugins}.txt >${zsh_plugins}.zsh
  )
fi
source ${zsh_plugins}.zsh

# ============================================================
# Prompt (Starship)
# ============================================================
eval "$(starship init zsh)"

# ============================================================
# Shell enhancements
# ============================================================
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
zsh-defer -c 'FAST_HIGHLIGHT_STYLES[global-alias]="fg=green"'

# fzf — fuzzy finder integration
# Ctrl+R = fuzzy history search, Ctrl+T = fuzzy file finder, Alt+C = fuzzy cd
source <(fzf --zsh)

# history substring search — Up/Down matches anywhere in command, not just prefix
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# zoxide — smart cd that learns your directories
eval "$(zoxide init zsh)"

# ============================================================
# Homebrew
# ============================================================
export HOMEBREW_NO_AUTO_UPDATE=1   # brew autoupdate handles this on a schedule
export HOMEBREW_NO_ENV_HINTS=1     # suppress "Adjust how often..." hints

# ============================================================
# Editor
# ============================================================
export EDITOR=micro
export VISUAL="$EDITOR"

# ============================================================
# Aliases and functions
# ============================================================
source "$HOME/.config/shell/aliases/eza.zsh"
source "$HOME/.config/shell/aliases/custom.zsh"
source "$HOME/.config/shell/aliases/theydo.zsh"

# ============================================================
# PATH and runtime setup
# ============================================================
# n — Node.js version manager
export N_PREFIX=$HOME/.n
export PATH=$N_PREFIX/bin:$PATH

# bun — completions + binary
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# local binaries (dots CLI, etc.)
export PATH="$HOME/.local/bin:$PATH"

# mise — polyglot runtime manager
eval "$(mise activate zsh)"

# wt — git worktree tool shell integration
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
