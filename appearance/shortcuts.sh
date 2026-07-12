#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$HOME/.config"

cp -f "$REPO_DIR/.config/kglobalshortcutsrc" \
      "$HOME/.config/"

