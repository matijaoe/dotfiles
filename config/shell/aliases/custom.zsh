_exists() {
  command -v $1 > /dev/null 2>&1
}

# Editor
alias vsc="cursor ."
alias zshrc="cursor ~/.zshrc"

# Homebrew
alias bi="brew install"
alias brewall='brew update && brew upgrade --greedy && brew cleanup'

# Safety
if _exists trash; then
  alias rm="trash"
else
  alias rm="rm -i"
fi

alias mv="mv -i"
alias cp="cp -i"

# Files
alias o="open"
alias oo="open ."

if _exists bat; then
  alias cat="bat"
fi

# Shell
alias clr="clear"
alias q="~ && clear"
alias path="echo ${PATH//:/$'\n'}"
alias src="exec zsh"

# Fix .. showing as red
alias ".."="cd .." 

# Network
alias net="networkQuality"
alias pw="openssl rand -base64 30 | pbcopy && echo 'Password copied to clipboard'"
alias localip="ipconfig getifaddr en0"
alias ip="curl http://ipecho.net/plain; echo"

function ports() {
  lsof -nP -iTCP -sTCP:LISTEN
}

function killport() {
  lsof -ti tcp:"$1" | xargs kill -9
}

# What is this command actually?”
alias wh='type -a'

# GitHub
alias ghb="gh browse"

# ff = "find filename" anywhere: fast global name search, includes dotfiles, but skips junk dirs (node_modules/dist/build/etc.)
function ff() {
  fd -i "$1" . \
    --hidden \
    --exclude .git \
    --exclude node_modules \
    --exclude dist \
    --exclude build \
    --exclude .next \
    --exclude coverage \
    --exclude .turbo
}

# rgf = repo-focused filename search: lists tracked/non-ignored files (respects .gitignore) then filters by name
function rgf() { rg --files | rg -i "$1"; }

# rgi = content search: search INSIDE files for text/code (case-insensitive; respects .gitignore)
alias rgi='rg -i'

# Navigation
take() { mkdir -p "$@" && cd "${@:$#}"; }

alias dl="~/Downloads"
alias dt="~/Desktop"
alias dc="~/Documents"
alias dev="~/Developer"

# Tools
alias lg="lazygit"
alias ld="lazydocker"
alias lwt="lazyworktree"
alias dockerlist='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"'

alias see="glow"
alias "?"="tldr"

# Run cursor agent headless
a() {
  local model=anthropic/claude-haiku-4-5
  opencode run -m $model "$@"
}

alias ..="cd .." 

