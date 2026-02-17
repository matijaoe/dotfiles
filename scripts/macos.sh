#!/bin/bash

# macOS defaults
# Run: ./setup.sh --macos (or directly: bash scripts/macos.sh)
# Some changes require a logout/restart to take effect.

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

# Close System Settings to prevent it from overriding changes
osascript -e 'tell application "System Settings" to quit' 2>/dev/null

###############################################################################
# Language & Region                                                           #
###############################################################################

defaults write NSGlobalDomain AppleLanguages -array "en" "hr"
defaults write NSGlobalDomain AppleLocale -string "en_US@currency=EUR"

###############################################################################
# Keyboard & Input                                                            #
###############################################################################

# Fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for accent characters (enable key repeat instead)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable auto-period (double space inserts period)
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

###############################################################################
# Dock                                                                        #
###############################################################################

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# No auto-hide delay
defaults write com.apple.dock autohide-delay -float 0

# Don't show recent apps
defaults write com.apple.dock show-recents -bool false

# Icon size
defaults write com.apple.dock tilesize -int 64

# Magnification
defaults write com.apple.dock magnification -bool true

# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Scale effect for minimize
defaults write com.apple.dock mineffect -string "scale"

###############################################################################
# Finder                                                                      #
###############################################################################

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Default to list view (Nlsv=list, clmv=column, icnv=icon, glyv=gallery)
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Sort folders before files
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# New Finder windows open Home (PfHm=Home, PfLo=custom path)
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
# Alternative: open Downloads
# defaults write com.apple.finder NewWindowTarget -string "PfLo"
# defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"

# Avoid .DS_Store files on network and USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show ~/Library folder
chflags nohidden ~/Library

# Snap-to-grid for desktop icons
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null

###############################################################################
# Screenshots                                                                 #
###############################################################################

# Save to ~/Pictures/Screenshots
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"

###############################################################################
# Safari                                                                      #
###############################################################################

# Don't send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

# Auto-update extensions
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

###############################################################################
# Activity Monitor                                                            #
###############################################################################

# Show main window on launch
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Show CPU usage in Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Other                                                                       #
###############################################################################

# Silence terminal login banner
touch ~/.hushlogin

# Create Developer directory
mkdir -p ~/Developer

# Spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.springing.delay -float 0.5

###############################################################################
# Restart affected apps                                                       #
###############################################################################

for app in "Activity Monitor" "cfprefsd" "Dock" "Finder" "Safari" "SystemUIServer"; do
  killall "${app}" &>/dev/null || true
done

echo "macOS defaults applied. Some changes require a logout/restart."

###############################################################################
# Dock layout                                                                 #
###############################################################################

if [[ -f "$HOME/.dotfiles-profile" ]]; then
  PROFILE=$(cat "$HOME/.dotfiles-profile")
  if [[ -f "$DOTFILES/scripts/dock-apply.sh" ]]; then
    echo "Applying Dock layout for $PROFILE..."
    bash "$DOTFILES/scripts/dock-apply.sh" "$PROFILE"
  fi
fi
