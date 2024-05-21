Helpful resources

- https://www.stuartellis.name/articles/mac-setup/
- https://www.robinwieruch.de/mac-setup-web-development/

## System Preferences

- Security & Privacy
  - Under _General_, set _require a password after sleep or screen saver begins_ to _immediately_
  - Under _General_, click _Advanced…_ and select _Require an administrator password to access system-wide preferences_
  - Under _Firewall_, click _Turn Firewall On_.
  - Under _Privacy_, select _Analytics & Improvements_ and ensure that the options are not enabled.
  - Add Browser to "Screen Recording "
  - Turn on File Vault
- Appearance
  - Dark mode
- Desktop & Dock
  - Remove most apps
  - Automatic hide
  - Show recent applications: off
  - Minimize windows using: Scale Effect
  - Turn on magnification
  - Widgets -> Monochrome
  - Disable all hot corners
- Display
  - Nightshift
- Siri
  - disabled
- Trackpad
  - Swipe between pages: Scroll left or right with two fingers
  - App Exposé - Swipe down with three fingers
- Keyboard
  - Turn keyboard backlight off after inactivity - After 1 Minute
  - Text Input
    - disable "Capitalize word automatically"
    - disable "Add full stop with double-space"
    - disable "Use smart quotes and dashes"
    - use `"` for double quotes
    - use `'` for single quotes
    - Spelling: US English
  - Keyboard shortcuts
    - Spotlight
      - Disable CMD + Space (will use Raycast)
    - Screenshots
      - Disable all but video (will use CleanshotX or Shottr)
    - TODO: will overwrite some shortcuts
- Finder
  - General
    - New windows shows: [user]
  - Tags - disable all
  - Sidebar
    - Applications, Desktop, Downloads, Movies, Pictures, [user]
    - iCloud Drive
    - Recent Tags: off
  - Advanced
    - Show all filename extensions ✅
    - Remove items from bin after 30 days
    - When performing a search: Search the current folder
  - Menu Bar -> View
    - Show View Options
      - Group by: none
      - Sort by: Kind
      - Calculate all sizes ✅
  - Create ~/Developer folder manually
- Storage
  - Remove Garage Band & Sound Library

## System Preferences (via Terminal)

### Install & update

TODO: setup dotfiles similar to https://github.com/myshov/dotfiles?tab=readme-ov-file
Install any updates

```bash
sudo softwareupdate -i -a
```

- download from App Store
- install command line tools

```bash
xcode-select --install
```

## Homebrew

Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Setup [Homebrew Autoupdate](https://github.com/DomT4/homebrew-autoupdate)

```bash
brew tap homebrew/autoupdate
```

Run

```bash
brew  autoupdate start 43200 --upgrade --cleanup --immediate --sudo
```

This will upgrade all your casks and formulae every 12 hours and on every system boot.
If a sudo password is required for an upgrade, a GUI to enter your password will be displayed.
Also, it will clean up every old version and left-over files.

Casks that have built-in auto-updates enabled by default will not be upgraded.
To upgrade those, run

```bash
brew update
brew upgrade --greedy
```

### Install packages

- TODO: link to files

```bash
xargs brew install < brew.txt
```

```bash
xargs brew install --cask < brew-casks.txt
```

## Development

### n

Install

- Installation with confirmation prompt to default location `$HOME/n` and installation of the latest LTS Node.js version:

```bash
curl -L https://bit.ly/n-install | bash
```

- Automated installation to default location `$HOME/n` and installation of the latest LTS Node.js version:

```bash
curl -L https://bit.ly/n-install | bash -s -- -y
```

[Environment variables](https://stackoverflow.com/questions/61677951/why-n-throws-error-error-sudo-required-or-change-ownership-or-define-n-prefi)

- Add to `.zshrc` [stack overflow](https://stackoverflow.com/questions/61677951/why-n-throws-error-error-sudo-required-or-change-ownership-or-define-n-prefi)

```bash
# Added by n-install (see http://git.io/n-install-repo).
export N_PREFIX=$HOME/.n
export PATH=$N_PREFIX/bin:$PATH
```

install node versions

```
n lts
n latest
n 18
n 20
n 22
```

## Oh My Zsh

Install

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Update everything

```bash
omz update
```

### Plugins

Built-in

```bash
    git
    sudo # double ESC
    vscode # vsc
    python # py
    aliases # als <searchTerm>
    copypath
    brew
    zsh-interactive-cd
```

Custom (start new terminal sessions after install)

- [pnpm.plugin.zsh](https://github.com/matijaoe/pnpm.plugin.zsh)

```bash
git clone --depth=1 https://github.com/mat2ja/pnpm.plugin.zsh.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/pnpm
```

```bash
# include in plugins
plugins=(... pnpm)
```

- [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use?tab=readme-ov-file#installation)

```bash
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_CUSTOM/plugins/you-should-use
```

```bash
# include in plugins
plugins=(
    # ...
    you-should-use
    # ...
)
```

- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

```bash
brew install zsh-syntax-highlighting
```

```bash
echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
```

- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)

```bash
brew install zsh-autosuggestions
```

To activate the autosuggestions, add the following at the end of your `.zshrc`:

```bash
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

- [zsh completions](https://github.com/zsh-users/zsh-completions)

```bash
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
```

Add it to `FPATH` in your `.zshrc` by adding the following line before `source "$ZSH/oh-my-zsh.sh"`:

```bash
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
```

- [thefuck](https://github.com/nvbn/thefuck?tab=readme-ov-file#installation)
  add to `.zshrc`

```bash
eval $(thefuck --alias)
```

## Set up aliases

TODO: link to dotfiles

```bash
export EDITOR=nano
export VISUAL="$EDITOR"

_exists() {
  command -v $1 > /dev/null 2>&1
}

# Avoid stupidity with trash-cli:
# https://github.com/sindresorhus/trash-cli
if _exists trash; then
  alias rm="trash"
else
  alias rm="rm -i"
fi

alias mv="mv -i"
alias cp="cp -i"

alias o="open"
alias oo="open ."

# cat with syntax highlighting
# https://github.com/sharkdp/bat
if _exists bat; then
  alias cat="bat"
fi

# Just bcoz clr shorter than clear
alias clr="clear"

# Go to the /home/$USER (~) directory and clears window of your terminal
alias q="~ && clear"

# Show $PATH in readable view
alias path="echo ${PATH//:/$'\n'}"

# Quick reload of zsh environment
alias src="exec zsh"

alias c="pbcopy"

alias net="networkQuality"
alias pw="openssl rand -base64 30 | pbcopy && echo 'Password copied to clipboard'"

alias ghb="gh browse"

# get machine's ip address
alias localip="ipconfig getifaddr en0"
alias ip="curl http://ipecho.net/plain; echo"

# tools
alias rate="curl rate.sx" # crypto
alias wttr="curl wttr.in"

qr() {
  local STRING="$1"
  if [[ -z "$STRING" ]]; then
    echo "Usage: qr <STRING>"
    return 1
  fi
  curl qrenco.de/"$STRING"
}

# directories
alias dl="~/Downloads"
alias dt="~/Desktop"
alias dev="~/Developer"
```

TODO:

- thefuck
- https://github.com/microsoft/inshellisense

## SSH

[guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

Generate a new SSH key
```bash
ssh-keygen -t ed25519 -C "github@matijao.com"
```
Add SSH key to the ssh-agent

- Start the ssh-agent in the background.
```bash
eval "$(ssh-agent -s)"
```
- check to see if your ~/.ssh/config file exists in the default location.
```bash
open ~/.ssh/config
```

- If the file doesn't exist, create the file.
```bash
touch ~/.ssh/config
```

- Open your `~/.ssh/config` file, then modify the file to contain the following lines. If your SSH key file has a different name or path than the example code, modify the filename or path to match your current setup.
```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

- Add your SSH private key to the ssh-agent and store your passphrase in the keychain. If you created your key with a different name, or if you are adding an existing key that has a different name, replace id_ed25519 in the command with the name of your private key file.
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```


## Apps

NPM

```bash
npm install --global trash-cli
```

CURL

- https://github.com/chubin/awesome-console-services
