#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOT_DIR="$REPO_DIR/boot"

if [[ ! -d "$BOOT_DIR" ]]; then
    echo "boot folder not found"
    read -rp "Press Enter to return..."
    exit 0
fi

mapfile -t SCRIPTS < <(
    find "$BOOT_DIR" -maxdepth 1 -type f -name "*.sh" | sort
)

if [[ ${#SCRIPTS[@]} -eq 0 ]]; then
    echo "No scripts in boot folder"
    read -rp "Press Enter to return..."
    exit 0
fi

SELECTED=$(
    printf "%s\n" "${SCRIPTS[@]}" |
    sed "s|$BOOT_DIR/||" |
    fzf \
        --multi \
        --layout=reverse \
        --border=rounded \
        --height=75% \
        --prompt="boot: " \
        --pointer="▶ " \
        --marker="*" \
        --bind 'tab:toggle' \
        --bind 'ctrl-a:select-all' \
        --bind 'ctrl-d:deselect-all' \
        --bind 'esc:abort' \
        --color=bg:-1,bg+:#112240,fg:#d0d0d0,fg+:#ffffff \
        --color=border:#4A6FA5,header:#6A9EFF,info:#6A9EFF \
        --color=pointer:#6A9EFF,marker:#6A9EFF,prompt:#6A9EFF \
        --color=spinner:#6A9EFF,hl:#6A9EFF,hl+:#8BB8FF
) || exit 0

[[ -z "$SELECTED" ]] && exit 0

while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    bash "$BOOT_DIR/$name"
done <<< "$SELECTED"

echo
read -rp "Press Enter to return..."