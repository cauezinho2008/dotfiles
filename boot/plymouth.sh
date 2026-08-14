#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# CachyOS boot optimizer — Plymouth
#
# Ensures the fast "cachyos" splash theme is used (NOT the
# "cachyos-bootanimation" theme which adds ~4s to boot) and
# rebuilds the initramfs so the change is persistent.
#
# Usage: plymouth.sh [--dry-run] [--restore]
# ==========================================================

BACKUP_ROOT="/var/backups/cachyos-boot-optimizer"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

DESIRED_THEME="cachyos"
AVOID_THEME="cachyos-bootanimation"
PLYMOUTH_CONF="/etc/plymouth/plymouthd.conf"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"

DRY_RUN=0
RESTORE=0
CHANGED=0

# ---- output helpers -------------------------------------------------

if [[ -t 1 ]]; then
    c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_cyan=$'\033[36m'; c_reset=$'\033[0m'
else
    c_green=; c_yellow=; c_red=; c_cyan=; c_reset=
fi

info() { echo "${c_cyan}[plymouth]${c_reset} $*"; }
ok()   { echo "${c_green}  ✔ $*${c_reset}"; }
warn() { echo "${c_yellow}  ! $*${c_reset}"; }
die()  { echo "${c_red}  ✘ $*${c_reset}"; exit 1; }

[[ "$EUID" -eq 0 ]] || die "Run as root."

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTION]

CachyOS Plymouth splash optimizer.

  --dry-run   print what would be changed without modifying anything
  --restore   restore the latest backup
  -h, --help  show this help
EOF
}

# ---- backup / restore ----------------------------------------------

backup_file() {
    local f="$1"
    [[ -f "$f" ]] || return 0
    mkdir -p "$BACKUP_DIR$(dirname "$f")"
    cp -a "$f" "$BACKUP_DIR$f"
    info "backed up: $f"
}

restore_latest() {
    local latest
    latest="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n1)"
    [[ -n "$latest" ]] || die "No backups found under $BACKUP_ROOT"
    info "restoring from: $latest"
    while IFS= read -r f; do
        local rel="${f#"$latest"/}"
        mkdir -p "/$(dirname "$rel")"
        cp -a "$f" "/$rel"
        ok "restored: /$rel"
    done < <(find "$latest" -type f)
    echo
    info "rebuilding initramfs after restore..."
    mkinitcpio -P
}

# ---- theme ----------------------------------------------------------

set_theme() {
    if [[ ! -d "/usr/share/plymouth/themes/$DESIRED_THEME" ]]; then
        warn "theme directory missing: /usr/share/plymouth/themes/$DESIRED_THEME"
    fi

    local current
    current="$(plymouth-set-default-theme 2>/dev/null | tail -n1 || true)"

    if [[ "$current" == "$DESIRED_THEME" ]]; then
        ok "plymouth theme already '$DESIRED_THEME'"
    else
        if [[ "$current" == "$AVOID_THEME" ]]; then
            warn "current theme '$AVOID_THEME' adds ~4s to boot — switching to '$DESIRED_THEME'"
        fi
        if [[ $DRY_RUN -eq 1 ]]; then
            info "would run: plymouth-set-default-theme $DESIRED_THEME"
        else
            backup_file "$PLYMOUTH_CONF"
            plymouth-set-default-theme "$DESIRED_THEME"
            ok "set plymouth theme to '$DESIRED_THEME'"
        fi
        CHANGED=1
    fi
}

# ---- initramfs ------------------------------------------------------

rebuild_initramfs() {
    if [[ $CHANGED -eq 1 ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            info "would run: mkinitcpio -P"
        else
            backup_file "$MKINITCPIO_CONF"
            mkinitcpio -P
            ok "initramfs rebuilt"
        fi
    else
        ok "no initramfs rebuild needed"
    fi
}

# ---- report ---------------------------------------------------------

report() {
    echo
    echo "=== Plymouth report ==="
    echo "  theme: $(plymouth-set-default-theme 2>/dev/null | tail -n1 || echo unknown)"
}

# ---- main -----------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --restore) RESTORE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
done

info "Plymouth splash optimizer"

if [[ "$RESTORE" -eq 1 ]]; then
    restore_latest
    report
    exit 0
fi

set_theme
rebuild_initramfs
report
exit 0