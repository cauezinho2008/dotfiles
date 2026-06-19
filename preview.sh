#!/usr/bin/env bash
set -euo pipefail

ITEM="${1:-}"
TYPE="${2:-config}"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PREVIEW_DIR="$REPO_DIR/preview"

show_image() {
    local img="$1"

    chafa \
        --size="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}" \
        --animate=off \
        --symbols vhalf \
        "$img"
}

show_text() {
    local txt="$1"

    if command -v bat >/dev/null 2>&1; then
        bat --style=plain --color=always "$txt"
    else
        cat "$txt"
    fi
}

# ==========================================================
# Priority:
# txt > png > jpg > webp
# ==========================================================

if [[ -f "$PREVIEW_DIR/$ITEM.txt" ]]; then
    show_text "$PREVIEW_DIR/$ITEM.txt"
    exit 0
fi

for ext in png jpg jpeg webp; do
    if [[ -f "$PREVIEW_DIR/$ITEM.$ext" ]]; then
        show_image "$PREVIEW_DIR/$ITEM.$ext"
        exit 0
    fi
done

echo "No preview available."
