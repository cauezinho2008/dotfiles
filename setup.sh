#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Copying .config..."
cp -rv "$REPO_DIR/.config/." "$HOME/.config/"

echo "Copying .poshthemes..."
cp -rv "$REPO_DIR/.poshthemes" "$HOME/"

echo "Done!"
