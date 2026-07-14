#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.local/share/PrismLauncher/prismlauncher.cfg"

if [[ -f "$CFG" ]]; then
    sed -i "s|\$HOME|$HOME|g" "$CFG"
fi

pkill prismlauncher 2>/dev/null || true