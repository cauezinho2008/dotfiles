#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup"

PACKAGES_FILE="$REPO_DIR/packages.txt"

# =========================

# Load packages

# =========================

if [[ -f "$PACKAGES_FILE" ]]; then
mapfile -t PACKAGES < "$PACKAGES_FILE"
else
echo "packages.txt not found!"
exit 1
fi

# =========================

# Detect distro

# =========================

source /etc/os-release

case "$ID" in
arch|cachyos|endeavouros|manjaro)
PKG_INSTALL="sudo pacman -S --needed"
PKG_CHECK="pacman -Q"
;;
ubuntu|debian|linuxmint|pop)
PKG_INSTALL="sudo apt install -y"
PKG_CHECK="dpkg -s"
sudo apt update
;;
fedora)
PKG_INSTALL="sudo dnf install -y"
PKG_CHECK="rpm -q"
;;
*)
echo "Unsupported distro: $ID"
exit 1
;;
esac

echo "Detected: $PRETTY_NAME"
echo

# =========================

# Check missing packages

# =========================

MISSING=()

for pkg in "${PACKAGES[@]}"; do
if ! $PKG_CHECK "$pkg" >/dev/null 2>&1; then
MISSING+=("$pkg")
fi
done

# =========================

# Install packages

# =========================

if [[ ${#MISSING[@]} -eq 0 ]]; then
echo "All packages already installed."
else
echo "Missing packages:"
printf " - %s\n" "${MISSING[@]}"
echo

```
read -rp "Install packages? [A]ll / [S]elect / [N]one: " choice

case "${choice,,}" in
    a|"")
        $PKG_INSTALL "${MISSING[@]}"
        ;;
    s)
        echo "Enter numbers (space separated):"
        for i in "${!MISSING[@]}"; do
            echo "$((i+1))) ${MISSING[$i]}"
        done
        read -rp "> " sel

        INSTALL=()
        for n in $sel; do
            [[ "$n" =~ ^[0-9]+$ ]] && INSTALL+=("${MISSING[$((n-1))]}")
        done

        [[ ${#INSTALL[@]} -gt 0 ]] && $PKG_INSTALL "${INSTALL[@]}"
        ;;
    *)
        echo "Skipping package installation."
        ;;
esac
```

fi

# =========================

# Backup system

# =========================

echo
read -rp "Backup existing configs before overwrite? [Y/n]: " do_backup

if [[ "${do_backup,,}" != "n" ]]; then
TS="$(date +%Y%m%d-%H%M%S)"
CURRENT_BACKUP="$BACKUP_DIR/$TS"

```
echo "Creating backup at $CURRENT_BACKUP ..."
mkdir -p "$CURRENT_BACKUP"

for item in "$REPO_DIR"/.*; do
    base="$(basename "$item")"

    case "$base" in
        "."|".."|".git"|".github")
            continue
            ;;
    esac

    if [[ -e "$HOME/$base" ]]; then
        cp -a "$HOME/$base" "$CURRENT_BACKUP/" 2>/dev/null || true
    fi
done

echo "Backup done."
```

else
echo "Skipping backup."
fi

# =========================

# Restore system

# =========================

echo
read -rp "Restore configs? [A]ll / [S]elect / [N]one: " restore_choice

restore_item() {
local src="$1"
local name
name="$(basename "$src")"

```
if [[ "$name" == ".config" ]]; then
    mkdir -p "$HOME/.config"
    cp -a "$src/." "$HOME/.config/"
else
    cp -a "$src" "$HOME/"
fi
```

}

case "${restore_choice,,}" in
a|"")
for item in "$REPO_DIR"/.*; do
base="$(basename "$item")"
case "$base" in
"."|".."|".git"|".github")
continue
;;
esac
restore_item "$item"
done
;;
s)
for item in "$REPO_DIR"/.*; do
base="$(basename "$item")"
case "$base" in
"."|".."|".git"|".github")
continue
;;
esac

```
        read -rp "Restore $base ? [Y/n]: " ans
        [[ "${ans,,}" != "n" ]] && restore_item "$item"
    done
    ;;
*)
    echo "Skipping restore."
    ;;
```

esac

# =========================

# Backup restore menu

# =========================

echo
echo "Backup history:"
ls "$BACKUP_DIR" 2>/dev/null || echo "No backups found"

read -rp "Restore a previous backup? (enter folder name or leave empty): " restore_old

if [[ -n "$restore_old" ]]; then
OLD="$BACKUP_DIR/$restore_old"
if [[ -d "$OLD" ]]; then
cp -a "$OLD"/. "$HOME/"
echo "Backup restored."
else
echo "Backup not found."
fi
fi

echo
echo "Done."
