# ============================================================
# Personal temp aliases — to be categorized later
# Migrated from live .zshrc on 2025-02-18
# ============================================================

# Clipboard
alias copy="pbcopy"

# Navigation
alias seed="cd ~/Documents/SEED"

# SSH
alias sshh="ssh homelab"

# Fun / info
alias rate="curl rate.sx"
alias wttr="curl wttr.in"

# yt-dlp
alias ytdl="yt-dlp -f bestvideo+bestaudio --embed-thumbnail "
alias ytdla="yt-dlp -x -f bestaudio --embed-thumbnail --audio-quality 0 "
alias ytdlaf="yt-dlp -x -f bestaudio --embed-thumbnail --audio-quality 0 --audio-format "

# ffmpeg metadata
alias ffmeta="ffprobe -v quiet -print_format json -show_format "

# QR code generation
qr() {
  local STRING="$1"
  if [[ -z "$STRING" ]]; then
    echo "Usage: qr <STRING>"
    return 1
  fi
  curl qrenco.de/"$STRING"
}

# Python venv helpers
va() {
  local search_dir
  search_dir=$(pwd)
  while [ "$search_dir" != "/" ]; do
    if [ -d "$search_dir/.venv" ]; then
      source "$search_dir/.venv/bin/activate"
      echo "Activated venv at: $search_dir/.venv"
      return 0
    fi
    search_dir=$(dirname "$search_dir")
  done
  echo "Error: No .venv found in this directory or any parent directory."
  return 1
}

alias activate='source $(find . -wholename "*/bin/activate")'

# Bitcoin price
btc() {
  curl -s https://api.coinbase.com/v2/prices/BTC-USD/spot \
  | jq -r '.data.amount' \
  | python3 -c "import sys; v=float(sys.stdin.read()); print('$' + format(int(round(v)), ','))"
}

# OpenSSL encrypt/decrypt
openssl_encrypt() {
  local input_file="$1"
  local output_file="${2:-${input_file}.aes}"
  openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -in "$input_file" -out "$output_file"
}

openssl_decrypt() {
  local input_file="$1"
  local output_file="${2:-${input_file%.aes}}"
  openssl enc -d -aes-256-cbc -salt -pbkdf2 -iter 100000 -in "$input_file" -out "$output_file"
}
