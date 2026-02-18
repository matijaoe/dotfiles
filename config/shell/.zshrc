# ============================================================
# Homebrew (must be first — tools like starship, zoxide, mise live here)
# ============================================================
eval "$(/opt/homebrew/bin/brew shellenv)"

# ============================================================
# Completions
# ============================================================
fpath=(~/.config/shell/completions $fpath)
[[ -d "$HOME/.zsh/completions" ]] && fpath=("$HOME/.zsh/completions" $fpath)

# ============================================================
# Antidote plugin manager
# ============================================================
# compile plugins to bytecode for faster loading
zstyle ':antidote:*' zcompile 'yes'
# use short names in `antidote list` instead of mangled URLs
zstyle ':antidote:bundle' use-friendly-names 'yes'

zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
if [[ ! -s ${zsh_plugins}.zsh || ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
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

# prevent autosuggestion flicker when using Up/Down with history-substring-search
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(history-substring-search-up history-substring-search-down)
ZSH_AUTOSUGGEST_CLEAR_WIDGETS=("${(@)ZSH_AUTOSUGGEST_CLEAR_WIDGETS:#(up|down)-line-or-history}")

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
source "$HOME/.config/shell/aliases/personal-temp.zsh"
source "$HOME/.config/shell/aliases/theydo.zsh"

# ============================================================
# PATH and runtime setup
# ============================================================
# prepend to PATH only if not already present
path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

# n — Node.js version manager
export N_PREFIX=$HOME/.n
path_prepend "$N_PREFIX/bin"

# bun — completions + binary
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"

# local binaries (dots CLI, etc.)
path_prepend "$HOME/.local/bin"

# mise — polyglot runtime manager
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# wt — git worktree tool shell integration
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# opencode
path_prepend "$HOME/.opencode/bin"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
path_prepend "$PNPM_HOME"

# deno
[ -s "$HOME/.deno/env" ] && source "$HOME/.deno/env"
