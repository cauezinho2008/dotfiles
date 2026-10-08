#!/usr/bin/env bash
set -euo pipefail

URL="https://github.com/cauezinho2008/dotfiles.git"

# remove all previous unfinished sessions
find /tmp -maxdepth 1 -type d -name "caue-dotfiles-*" -exec rm -rf {} + 2>/dev/null || true

DIR="$(mktemp -d /tmp/caue-dotfiles-XXXXX)"

spinner() {
    local frames=(' / ' ' - ' ' \ ' ' | ')
    local i=0
    while true; do
        printf '\r%s  %s' "$1" "${frames[i]}"
        i=$(( (i + 1) % 4 ))
        sleep 0.1
    done
}

clear
spinner "Downloading files..." &
spin=$!
trap 'kill "$spin" 2>/dev/null' EXIT

git clone --quiet --depth 2 $URL $DIR
kill "$spin" 2>/dev/null
clear



cleanup() {
    rm -rf "$DIR"
}

trap cleanup EXIT INT TERM

cd "$DIR"

bash "$DIR/main.sh"
