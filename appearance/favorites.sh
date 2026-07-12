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

echo "Updating SQLite database..."

{
    echo "BEGIN;"
    echo "DELETE FROM ResourceLink WHERE initiatingAgent='org.kde.plasma.favorites.applications';"

    for APP in "${FAVORITES[@]}"; do
        printf "INSERT INTO ResourceLink (usedActivity, initiatingAgent, targettedResource) VALUES(':global','org.kde.plasma.favorites.applications','%s');\n" "$APP"
    done

    echo "COMMIT;"
} | sqlite3 "$DB"
echo "Done."
