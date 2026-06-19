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

# ==========================================================
# Paths
# ==========================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

CONFIG_DIR="$REPO_DIR/.config"
LOCAL_SHARE_DIR="$REPO_DIR/.local/share"
POSH_DIR="$REPO_DIR/.poshthemes"

HOOKS_DIR="$REPO_DIR/hooks"
PREVIEW_DIR="$REPO_DIR/preview"

EXCLUDED_FILE="$REPO_DIR/excluded.txt"

BACKUP_ROOT="$HOME/.dotfiles-backup"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# ==========================================================
# Header
# ==========================================================

clear

gum style --foreground 39 --bold --align center "Copy Dotfiles"
echo
gum style --foreground 33 --align center "Tab: Toggle   Ctrl+A: All   Ctrl+D: None   Enter: Apply"
echo

# ==========================================================
# Exclusions
# ==========================================================

EXCLUDED=()

if [[ -f "$EXCLUDED_FILE" ]]; then
    mapfile -t EXCLUDED < <(
        grep -v '^#' "$EXCLUDED_FILE" |
        grep -v '^[[:space:]]*$'
    )
fi

is_excluded() {
    local item="$1"

    for ex in "${EXCLUDED[@]}"; do
        [[ "$item" == "$ex" ]] && return 0
    done

    return 1
}

# ==========================================================
# Build item registry
# ==========================================================

declare -A ITEMS

scan_dir() {
    local dir="$1"

    [[ ! -d "$dir" ]] && return

    while IFS= read -r item; do
        name="$(basename "$item")"

        is_excluded "$name" && continue

        ITEMS["$name"]=1
    done < <(find "$dir" -mindepth 1 -maxdepth 1 | sort)
}

scan_dir "$CONFIG_DIR"
scan_dir "$LOCAL_SHARE_DIR"
scan_dir "$POSH_DIR"

# hooks-only entries
if [[ -d "$HOOKS_DIR" ]]; then
    while IFS= read -r hook; do
        name="$(basename "$hook" .sh)"

        is_excluded "$name" && continue

        ITEMS["$name"]=1
    done < <(find "$HOOKS_DIR" -type f -name "*.sh" | sort)
fi

DISPLAY_LIST=()

for item in "${!ITEMS[@]}"; do
    DISPLAY_LIST+=("$item")
done

# ==========================================================
# Selection
# ==========================================================

SELECTED=$(
    printf "%s\n" "${DISPLAY_LIST[@]}" |
    sort |
    fzf \
        --multi \
        --layout=reverse \
        --border=rounded \
        --height=75% \
        --prompt="search: " \
        --pointer="▶ " \
        --marker="*" \
        --bind 'tab:toggle' \
        --bind 'ctrl-a:select-all' \
        --bind 'ctrl-d:deselect-all' \
        --bind 'esc:abort' \
        --color=bg:-1,bg+:#112240,fg:#d0d0d0,fg+:#ffffff \
        --color=border:#4A6FA5,header:#6A9EFF,info:#6A9EFF \
        --color=pointer:#6A9EFF,marker:#6A9EFF,prompt:#6A9EFF \
        --color=spinner:#6A9EFF,hl:#6A9EFF,hl+:#8BB8FF \
        --preview "$REPO_DIR/preview.sh {} config"\
        --preview-window=right:55%:wrap
) || exit 0

[[ -z "$SELECTED" ]] && exit 0

# ==========================================================
# Backup
# ==========================================================

if gum confirm "Create backup before applying?"; then
    BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    mkdir -p \
        "$BACKUP_DIR/.config" \
        "$BACKUP_DIR/.local/share" \
        "$BACKUP_DIR/.poshthemes"
fi

# ==========================================================
# Apply
# ==========================================================

while IFS= read -r name; do
    [[ -z "$name" ]] && continue

    gum spin --spinner dot --title "Applying $name..." -- sleep 0.1

    # config
    if [[ -e "$CONFIG_DIR/$name" ]]; then
        [[ -e "$HOME/.config/$name" && -d "${BACKUP_DIR:-}" ]] &&
            cp -a "$HOME/.config/$name" "$BACKUP_DIR/.config/" || true

        cp -a "$CONFIG_DIR/$name" "$HOME/.config/"
    fi

    # local share
    if [[ -e "$LOCAL_SHARE_DIR/$name" ]]; then
        [[ -e "$HOME/.local/share/$name" && -d "${BACKUP_DIR:-}" ]] &&
            cp -a "$HOME/.local/share/$name" "$BACKUP_DIR/.local/share/" || true

        cp -a "$LOCAL_SHARE_DIR/$name" "$HOME/.local/share/"
    fi

    # poshthemes
    if [[ -e "$POSH_DIR/$name" ]]; then
        [[ -e "$HOME/.poshthemes/$name" && -d "${BACKUP_DIR:-}" ]] &&
            cp -a "$HOME/.poshthemes/$name" "$BACKUP_DIR/.poshthemes/" || true

        mkdir -p "$HOME/.poshthemes"
        cp -a "$POSH_DIR/$name" "$HOME/.poshthemes/"
    fi

    # hooks
    if [[ -f "$HOOKS_DIR/$name.sh" ]]; then
        bash "$HOOKS_DIR/$name.sh"
    fi

done <<< "$SELECTED"

echo
gum style --foreground 39 --align center "Done."
echo
