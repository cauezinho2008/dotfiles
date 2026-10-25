#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Applying opencode config..."

mkdir -p "$HOME/.config/opencode"

# Copy config files
for file in opencode.jsonc cli.json; do
    if [[ -f "$REPO_DIR/.config/opencode/$file" ]]; then
        cp "$REPO_DIR/.config/opencode/$file" "$HOME/.config/opencode/"
        echo "  Applied $file"
    fi
done

echo "Opencode config applied."
