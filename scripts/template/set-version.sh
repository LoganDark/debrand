#!/usr/bin/env zsh
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <game-version>" >&2
	exit 1
fi

GAME_VERSION="$1"

if [[ ! -f "$REPO_DIR/gradle.properties" ]]; then
	echo "Error: gradle.properties not found in $REPO_DIR" >&2
	exit 1
fi

# Get properties for this version
props=$("$SCRIPTS_DIR/template/properties.sh" "$GAME_VERSION")

# Update gradle.properties
while IFS='=' read -r key value; do
	[[ -z "$key" || "$key" == \#* ]] && continue
	"$SCRIPTS_DIR/set-property.sh" "$key" "$value" "$REPO_DIR/gradle.properties"
done <<< "$props"

echo "Updated to Minecraft $GAME_VERSION:"
echo "$props"
echo ""

# Run ideaSyncTask
echo "Running ideaSyncTask..."
"$REPO_DIR/gradlew" -p "$REPO_DIR" ideaSyncTask
