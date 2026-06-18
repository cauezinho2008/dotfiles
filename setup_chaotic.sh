#!/usr/bin/env bash

set -euo pipefail

clear

gum style \
    --foreground 39 \
    --bold \
    --align center \
"Chaotic-AUR Setup"

echo

if grep -q "^\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null; then
    gum style \
        --foreground 82 \
        --align center \
"Chaotic-AUR already appears to be configured."

    echo
 read -rp "Press Enter to return to the menu..."
exit 0
fi

gum style \
    --foreground 33 \
    --align center \
"This will add the Chaotic-AUR repository."

echo

if ! gum confirm "Continue?"; then
    exit 0
fi

echo
gum style --foreground 39 "Installing keyring and mirrorlist..."
echo

sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

sudo pacman -U --needed \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
    sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
fi

echo
gum style --foreground 39 "Refreshing package databases..."
echo

sudo pacman -Sy

echo
gum style \
    --foreground 39 \
    --align center \
"Chaotic-AUR setup complete."

echo
read -rp "Press Enter to return to the menu..."
