#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

[[ -f "$REPO_DIR/.config/kcalcrc" ]] &&
    sed "s|\$HOME|$HOME|g" "$REPO_DIR/.config/kcalcrc" > "$HOME/.config/kcalcrc"

pkill kcalc 2>/dev/null || true