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

# GitHub
alias ghb="gh browse"

# Navigation
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

alias ..="cd .." 
