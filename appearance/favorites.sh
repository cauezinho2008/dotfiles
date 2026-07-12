#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

FAVORITES="$REPO_DIR/appearance/favorites.txt"

[[ -f "$FAVORITES" ]] || exit 1

# Build JS array
apps=""

while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^# ]] && continue
    apps="$apps\"$app\","
done < "$FAVORITES"

apps="[${apps%,}]"

qdbus org.kde.plasmashell \
    /PlasmaShell \
    org.kde.PlasmaShell.evaluateScript "
var desktops = desktops();

for (var i=0;i<desktops.length;i++) {

    var widgets = desktops[i].widgets();

    for (var j=0;j<widgets.length;j++) {

        if (widgets[j].type == 'org.kde.plasma.icontasks') {

            widgets[j].currentConfigGroup = ['General'];

            widgets[j].writeConfig(
                'launchers',
                $apps
            );
        }
    }
}
"

echo "Launcher favorites applied."
