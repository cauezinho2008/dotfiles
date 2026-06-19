#!/usr/bin/env bash
set -euo pipefail

ITEM="${1:-}"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PREVIEW_DIR="$REPO_DIR/preview"

clear_kitty_images() {
    if [[ "${TERM:-}" == xterm-kitty ]]; then
        # delete all visible kitty graphics
        printf '\033_Ga=d,d=A\033\\'
    fi
}

show_image() {
    local img="$1"

    # clear text
    printf '\033[2J\033[H'

    # clear kitty image layers
    if [[ -n "${KITTY_WINDOW_ID:-}" ]]; then
        printf '\033_Ga=d,d=A\033\\'
    fi

    chafa \
        --clear \
        --size="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}" \
        --animate=off \
        "$img"
}

show_text() {
    local txt="$1"

    clear_kitty_images
    printf '\033[H\033[2J'

    if command -v bat >/dev/null 2>&1; then
        bat --style=plain --color=always "$txt"
    else
        cat "$txt"
    fi
}

# txt first
if [[ -f "$PREVIEW_DIR/$ITEM.txt" ]]; then
    show_text "$PREVIEW_DIR/$ITEM.txt"
    exit 0
fi

# images after
for ext in png jpg jpeg webp; do
    if [[ -f "$PREVIEW_DIR/$ITEM.$ext" ]]; then
        show_image "$PREVIEW_DIR/$ITEM.$ext"
        exit 0
    fi
done

clear_kitty_images
printf '\033[H\033[2J'
echo "No preview available."
