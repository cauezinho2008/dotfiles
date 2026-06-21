#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$HOME/.local/share"

[[ -d "$REPO_DIR/.local/share/color-schemes" ]] &&
    cp -a "$REPO_DIR/.local/share/color-schemes" "$HOME/.local/share/"

plasma-apply-colorscheme BreezeDarker 2>/dev/null || true
