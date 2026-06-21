#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.config/fish/oh_my_posh"

fish -c '
set -U fish_greeting
'
