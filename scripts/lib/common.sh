#!/bin/bash

# Shared helpers for scripts in this repository.
# Requires: gum (https://github.com/charmbracelet/gum)

if [[ -n "${DOTFILES_COMMON_SH_LOADED:-}" ]]; then
  return 0
fi
DOTFILES_COMMON_SH_LOADED=1

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DOTFILES

# ============================================================
# Gum detection (used by setup.sh bootstrap)
# ============================================================
has_gum() { command -v gum &>/dev/null; }

# ============================================================
# Output helpers
# Icon is colored, text stays white.
# ============================================================
info()    { printf "  \033[34m•\033[0m %s\n" "$1"; }
success() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn()    { printf "  \033[33m!\033[0m %s\n" "$1"; }
error()   { printf "  \033[31m✗\033[0m %s\n" "$1"; }
summary() { printf "  \033[32m✓\033[0m \033[1m%s\033[0m\n" "$1"; }

section() {
  echo ""
  gum style --bold --foreground 6 "➤ $1"
}

command_exists() { command -v "$1" &>/dev/null; }

# Show profile line (skipped when running inside setup.sh which shows it once)
# Usage: show_profile "$PROFILE" "$@"  (passes original args to detect source)
show_profile() {
  [[ "${DOTFILES_SETUP:-}" == "1" ]] && return
  local profile="$1"; shift
  local source="saved"
  for arg in "$@"; do
    [[ "$arg" == "--work" || "$arg" == "--personal" ]] && source="specified" && break
  done
  printf "  \033[32m✓\033[0m Profile: \033[1;33m%s\033[0m \033[2m(%s)\033[0m\n\n" "$profile" "$source"
}

# ============================================================
# Interactive helpers (gum-powered)
# ============================================================

# Choose from a list of options. Usage: choose_one "opt1" "opt2" ...
choose_one() { gum choose "$@"; }

# Yes/no confirmation. Usage: confirm "Commit and push?"
confirm() {
  gum confirm "${1:-Continue?}" \
    --selected.background="2" \
    --selected.foreground="0" \
    --unselected.background="" \
    --unselected.foreground="7"
}

# ============================================================
# Profile helpers
# ============================================================

# Check for profile conflict and confirm before proceeding.
# Usage: check_profile_conflict "$PROFILE" [--saves-profile]
#   --saves-profile: use when the caller will write ~/.dotfiles-profile (e.g. setup.sh)
#                    omit for standalone scripts that only run once without changing saved profile
check_profile_conflict() {
  local profile="$1"
  local saves_profile=false
  [[ "${2:-}" == "--saves-profile" ]] && saves_profile=true

  local saved=""
  [[ -f "$HOME/.dotfiles-profile" ]] && saved="$(<"$HOME/.dotfiles-profile")"

  # No conflict: no saved profile, or profiles match
  [[ -z "$saved" || "$profile" == "$saved" ]] && return 0

  # Conflict detected
  printf "  \033[33m!\033[0m Saved profile is \033[1;33m%s\033[0m — you specified \033[1;33m%s\033[0m\n" "$saved" "$profile"
  if [[ "$saves_profile" == true ]]; then
    printf "  \033[34m•\033[0m This will update your saved profile from \033[1;33m%s\033[0m to \033[1;33m%s\033[0m\n" "$saved" "$profile"
    echo ""
    confirm "Switch to $profile and run setup?" || { warn "Aborted"; exit 0; }
  else
    printf "  \033[34m•\033[0m Running as \033[1;33m%s\033[0m for this script only — saved profile stays \033[1;33m%s\033[0m\n" "$profile" "$saved"
    echo ""
    confirm "Continue with $profile?" || { warn "Aborted"; exit 0; }
  fi
}

resolve_profile() {
  local profile=""
  for arg in "$@"; do
    case "$arg" in
      --work)     profile="work" ;;
      --personal) profile="personal" ;;
    esac
  done
  if [[ -z "$profile" && -f "$HOME/.dotfiles-profile" ]]; then
    profile="$(<"$HOME/.dotfiles-profile")"
  fi
  printf "%s" "$profile"
}

require_profile() {
  local profile
  profile="$(resolve_profile "$@")"

  if [[ -z "$profile" ]]; then
    error "No profile set. Use --work or --personal, or run: echo work > ~/.dotfiles-profile"
    return 1
  fi

  printf "%s" "$profile"
}
