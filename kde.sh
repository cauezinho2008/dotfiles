#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# Theme
# ==========================================================

export GUM_CHOOSE_CURSOR_FOREGROUND="#6A9EFF"
export GUM_CHOOSE_SELECTED_FOREGROUND="#6A9EFF"

export GUM_CONFIRM_PROMPT_FOREGROUND="#6A9EFF"
export GUM_CONFIRM_SELECTED_FOREGROUND="#FFFFFF"
export GUM_CONFIRM_SELECTED_BACKGROUND="#217CB5"

export GUM_INPUT_CURSOR_FOREGROUND="#6A9EFF"
export GUM_SPIN_SPINNER_FOREGROUND="#6A9EFF"

export FZF_DEFAULT_OPTS="
--color=bg:-1,bg+:#112240,fg:#d0d0d0,fg+:#ffffff
--color=border:#4A6FA5,header:#6A9EFF,info:#6A9EFF
--color=pointer:#6A9EFF,marker:#6A9EFF,prompt:#6A9EFF
--color=spinner:#6A9EFF,hl:#6A9EFF,hl+:#8BB8FF
"
# ==========================================================
# Paths
# ==========================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
APPEAR_DIR="$REPO_DIR/appearance"
ORDER_FILE="$APPEAR_DIR/order.txt"

[[ -d "$APPEAR_DIR" ]] || {
    echo "appearance folder not found"
    read -rp "Press Enter..."
    exit 1
}

[[ -f "$ORDER_FILE" ]] || {
    echo "order.txt not found"
    read -rp "Press Enter..."
    exit 1
}

# ==========================================================
# Load ordered entries
# ==========================================================

ENTRIES=()

while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue

    [[ -f "$APPEAR_DIR/$line.sh" ]] || continue

    ENTRIES+=("$line")
done < "$ORDER_FILE"

[[ ${#ENTRIES[@]} -eq 0 ]] && exit 1

# ==========================================================
# Header
# ==========================================================

clear

gum style \
    --foreground 39 \
    --bold \
    --align center \
"Appearance Manager"

echo

gum style \
    --foreground 33 \
    --align center \
"Tab: Toggle   Ctrl+A: All   Ctrl+D: None   Enter: Apply"

echo

# ==========================================================
# Selection
# ==========================================================

SELECTED=$(
    printf "%s\n" "${ENTRIES[@]}" |
    fzf \
        --multi \
        --layout=reverse \
        --border=rounded \
        --height=75% \
        --prompt="appearance: " \
        --pointer="▶ " \
        --marker="*" \
        --bind 'tab:toggle' \
        --bind 'ctrl-a:select-all' \
        --bind 'ctrl-d:deselect-all' \
        --preview "$REPO_DIR/preview.sh {} appearance" \
        --preview-window=right:55%:wrap:cycle
) || exit 0

[[ -z "$SELECTED" ]] && exit 0

# ==========================================================
# Confirmation
# ==========================================================

clear

gum style \
    --foreground 196 \
    --bold \
"This will override your current configuration for:"

echo

while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    echo " • $item"
done <<< "$SELECTED"

echo

gum style \
    --foreground 214 \
"This cannot be undone."

echo

gum confirm "Continue?" || exit 0

# ==========================================================
# Run selected in ORDER
# ==========================================================

while IFS= read -r ordered; do
    [[ -z "$ordered" ]] && continue

    while IFS= read -r selected; do
        [[ "$ordered" == "$selected" ]] || continue

      if ! gum spin \
    --spinner dot \
    --title "Applying $selected..." \
    -- bash "$APPEAR_DIR/$selected.sh"; then
    echo
    echo "Failed applying: $selected"
    read -rp "Press Enter to continue..."
fi

    done <<< "$SELECTED"

done < "$ORDER_FILE"

# ==========================================================
# Reload & Restart
# ==========================================================

echo
gum style \
    --foreground 33 \
    --bold \
    --align center \
"Reloading services..."

# Re-exec user daemon
systemctl --user daemon-reexec 2>/dev/null || true

# Reload KWin if running
if command -v qdbus &>/dev/null && qdbus org.kde.KWin &>/dev/null 2>&1; then
    qdbus org.kde.KWin /KWin org.kde.KWin.reloadConfig 2>/dev/null || true
fi

# Restart KGlobalAccel to pick up shortcuts
kquitapp6 kglobalacceld 2>/dev/null || true
sleep 0.5
kglobalacceld 2>/dev/null || true

# Restart KActivityManager for favorites
systemctl --user restart plasma-kactivitymanagerd.service 2>/dev/null || true
sleep 0.5

# Disable splash screen
kwriteconfig6 --file ksplashrc --group KSplash --key Engine none

# Restart plasmashell to pick up panel/applet changes
kquitapp6 plasmashell 2>/dev/null || true
sleep 1
kstart6 plasmashell >/dev/null 2>&1 || plasmashell >/dev/null 2>&1 &

echo
gum style \
    --foreground 82 \
    --align center \
"Appearance setup complete."
echo
