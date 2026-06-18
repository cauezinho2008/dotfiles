#!/usr/bin/env bash
#
# preview_image.sh
# Universal image preview wrapper for fzf.
# - Kitty -> native graphics
# - Sixel terminals -> chafa sixel
# - Everything else -> ANSI art

set -euo pipefail

IMAGE="${1:-}"

[[ -f "$IMAGE" ]] || {
    echo
    echo "No preview available."
    exit 0
}

# fzf exports these automatically.
COLS="${FZF_PREVIEW_COLUMNS:-80}"
LINES="${FZF_PREVIEW_LINES:-24}"

# ----------------------------------------------------------
# Kitty graphics protocol
# ----------------------------------------------------------

if [[ -n "${KITTY_WINDOW_ID:-}" ]] && command -v kitty >/dev/null 2>&1; then
    kitty +kitten icat \
        --clear \
        --stdin=no \
        --transfer-mode=memory \
        --place="${COLS}x${LINES}@0x0" \
        "$IMAGE" 2>/dev/null

    exit 0
fi

# ----------------------------------------------------------
# Sixel terminals (mlterm, xterm+sixel, foot, etc.)
# ----------------------------------------------------------

if chafa --help 2>/dev/null | grep -qi sixel; then
    chafa \
        --format=sixels \
        --size="${COLS}x${LINES}" \
        "$IMAGE" 2>/dev/null && exit 0
fi

# ----------------------------------------------------------
# ANSI / Unicode fallback
# ----------------------------------------------------------

exec chafa \
    --symbols vhalf \
    --size="${COLS}x${LINES}" \
    "$IMAGE"
