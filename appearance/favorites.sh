#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

FAVORITES_TXT="$SCRIPT_DIR/favorites.txt"
STATS="$HOME/.config/kactivitymanagerd-statsrc"
DB="$HOME/.local/share/kactivitymanagerd/resources/database"

[[ -f "$FAVORITES_TXT" ]] || { echo "Missing $FAVORITES_TXT"; exit 1; }
[[ -f "$STATS" ]] || { echo "Missing $STATS"; exit 1; }
[[ -f "$DB" ]] || { echo "Missing $DB"; exit 1; }

echo "Building favorites list..."

mapfile -t FAVORITES < <(
    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "$FAVORITES_TXT" |
    sed 's#^applications:##' |
    sed 's#^#applications:#'
)

ORDERING="$(IFS=,; echo "${FAVORITES[*]}")"

echo "Updating kactivitymanagerd-statsrc..."

grep '^\[Favorites-' "$STATS" |
tr -d '[]' |
while read -r GROUP; do
    kwriteconfig6 \
        --file "$STATS" \
        --group "$GROUP" \
        --key ordering \
        "$ORDERING"
done

# Notify kactivitymanagerd of the change
qdbus org.kde.kactivitymanagerd /ActivityManager/Activities org.kde.kactivitymanagerd.Activities.updateActivity "" 2>/dev/null || true

echo "Updating SQLite database..."

{
    echo "BEGIN;"
    echo "DELETE FROM ResourceLink WHERE initiatingAgent='org.kde.plasma.favorites.applications';"

    for APP in "${FAVORITES[@]}"; do
        printf "INSERT INTO ResourceLink (usedActivity, initiatingAgent, targettedResource) VALUES(':global','org.kde.plasma.favorites.applications','%s');\n" "$APP"
    done

    echo "COMMIT;"
} | sqlite3 "$DB"

# Restart plasmashell to pick up favorites (optional, but ensures immediate effect)
# kquitapp6 plasmashell 2>/dev/null || true
# sleep 1
# kstart5 plasmashell 2>/dev/null || plasmashell --replace &

echo "Done."
