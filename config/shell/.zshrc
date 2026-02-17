# ============================================================
# Completions
# ============================================================
fpath=(~/.config/shell/completions $fpath)

# ============================================================
# Zinit plugin manager
# ============================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

# ============================================================
# OMZ libraries — core shell behaviors
# (OMZL = individual OMZ lib files, loaded without the framework)
# ============================================================
zinit snippet OMZL::key-bindings.zsh         # Home/End, Ctrl+arrows, Up=prefix search, Ctrl+R
zinit snippet OMZL::directories.zsh          # auto_cd, ..., ...., pushd stack, cd -
zinit snippet OMZL::history.zsh              # 50k history, dedup, timestamps, ignore space
zinit snippet OMZL::completion.zsh           # tab completion setup + menu select
zinit snippet OMZL::theme-and-appearance.zsh # colored ls, grep --color

# ============================================================
# Prompt (Starship)
# ============================================================
eval "$(starship init zsh)"

# ============================================================
# OMZ plugins (OMZP = individual OMZ plugins)
# ============================================================
zinit snippet OMZP::git                      # git aliases (gst, gco, gp, etc.)
zinit snippet OMZP::sudo                     # double-ESC to prepend sudo
zinit snippet OMZP::copypath                 # copypath command
zinit snippet OMZP::brew                     # brew aliases (bubo, bubc, etc.)
zinit snippet OMZP::npm                      # npm completions + aliases

# ============================================================
# GitHub plugins (non-OMZ)
# ============================================================
zinit light matijaoe/pnpm.plugin.zsh               # pnpm aliases
zinit light MichaelAquilina/zsh-you-should-use   # reminds you of your aliases
zinit ice atclone'./zplug.zsh' atpull'%atclone'
zinit light g-plane/zsh-yarn-autocompletions     # yarn run/remove/add/why completions

# ============================================================
# Aliases plugin (multi-file, loaded locally)
# ============================================================
source ~/.local/share/zinit/plugins/omz-aliases/aliases.plugin.zsh

# ============================================================
# Shell enhancements
# ============================================================
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
zinit light zdharma-continuum/fast-syntax-highlighting
FAST_HIGHLIGHT_STYLES[global-alias]="fg=green"

# fzf — fuzzy finder integration
# Ctrl+R = fuzzy history search, Ctrl+T = fuzzy file finder, Alt+C = fuzzy cd
source <(fzf --zsh)

# fzf-tab — replaces default tab completion with fzf
zinit light Aloxaf/fzf-tab

# history substring search — Up/Down matches anywhere in command, not just prefix
zinit light zsh-users/zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# zoxide — smart cd that learns your directories
eval "$(zoxide init zsh)"

# delta — better git diffs (configured in ~/.gitconfig)

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
# Aliases — general
# ============================================================
alias vsc="cursor ."
alias zshrc="cursor ~/.zshrc"

alias ls="eza --icons --group-directories-first"
alias l="eza -l --git --icons --group-directories-first"
alias ll="eza -l --git --icons --group-directories-first"
alias la="eza -la --git --icons --group-directories-first"
alias lt="eza --tree --level=2 --icons --group-directories-first"
alias tree="eza --tree --icons --group-directories-first"
alias llm="eza -l --git --sort=modified --icons --group-directories-first"
alias l.="eza -a --icons | grep -E '^\.'"

alias bi="brew install"
alias brewall='brew update && brew upgrade --greedy && brew cleanup'

_exists() {
  command -v $1 > /dev/null 2>&1
}

if _exists trash; then
  alias rm="trash"
else
  alias rm="rm -i"
fi

alias mv="mv -i"
alias cp="cp -i"

alias o="open"
alias oo="open ."

if _exists bat; then
  alias cat="bat"
fi

alias clr="clear"
alias q="~ && clear"
alias path="echo ${PATH//:/$'\n'}"
alias src="source ~/.zshrc"

alias net="networkQuality"
alias pw="openssl rand -base64 30 | pbcopy && echo 'Password copied to clipboard'"

alias ghb="gh browse"

alias localip="ipconfig getifaddr en0"
alias ip="curl http://ipecho.net/plain; echo"

alias dl="~/Downloads"
alias dt="~/Desktop"
alias dev="~/Developer"

# ============================================================
# TheyDo
# ============================================================
tdr() { cd ~/Developer/TheyDo; }
td() { cd ~/Developer/TheyDo/theydo; }
tdweb() { cd ~/Developer/TheyDo/theydo/webapp; }
tdpw() { cd ~/Developer/TheyDo/theydo/packages/theydo-pw-e2e; }

td_run_yarn() {
  (td && yarn "$@")
}

alias lint="yarn lint:webapp"
alias format="yarn format:webapp"

alias fro="td_run_yarn dev:webapp"
alias ser="td_run_yarn dev:graphql-server"
alias worker="td_run_yarn dev:worker"
alias migrate="td_run_yarn workspace @theydo/core migration:run"
alias seed="td_run_yarn workspace @theydo/core elasticsearch:seed"
alias msser="migrate && seed && ser"
alias e2e="td_run_yarn workspace @theydo/pw-e2e test:ui"
alias icons="td_run_yarn workspace @theydo/iconography generate icons"
alias gql="td_run_yarn workspace @theydo/graphql generate-graphql"
alias gqlw="td_run_yarn workspace @theydo/webapp generate:graphql"
alias rmdist="td && cd graphql-server/ && rm -rf dist && yarn build && cd ../worker && rm -rf dist && yarn build && cd .."

# ============================================================
# Tools
# ============================================================
alias lg="lazygit"
alias ld="lazydocker"
alias lwt="lazyworktree"
alias dockerlist='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"'

ay-cd() {
  local dir
  dir="$(command ay cd "$@")"
  if [[ $? -eq 0 ]] && [[ -n "$dir" ]] && [[ -d "$dir" ]]; then
    cd "$dir"
  fi
}
alias acd='ay-cd'

# ============================================================
# PATH and runtime setup
# ============================================================
export N_PREFIX=$HOME/.n
export PATH=$N_PREFIX/bin:$PATH

[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"

eval "$(mise activate zsh)"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# opencode
export PATH=/Users/matijao/.opencode/bin:$PATH

# omnara
export OMNARA_INSTALL="$HOME/.omnara"
export PATH="$OMNARA_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
