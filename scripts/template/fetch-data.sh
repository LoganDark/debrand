#!/usr/bin/env zsh
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

BASE_META="https://meta.fabricmc.net"
BASE_MAVEN="https://maven.fabricmc.net"

mkdir -p "$DATA_DIR"

echo "Fetching installer versions..."
curl -sf "$BASE_META/v2/versions/installer" -o "$DATA_DIR/installer.json"

echo "Fetching game versions..."
curl -sf "$BASE_META/v2/versions/game" -o "$DATA_DIR/game.json"

echo "Fetching loader versions..."
curl -sf "$BASE_META/v2/versions/loader" -o "$DATA_DIR/loader.json"

echo "Fetching yarn versions..."
curl -sf "$BASE_META/v2/versions/yarn" -o "$DATA_DIR/yarn.json"

echo "Fetching JD list..."
curl -sf "$BASE_MAVEN/jdlist.txt" | jq -R -s 'split("\n") | map(select(. != ""))' > "$DATA_DIR/jdlist.json"

echo "Fetching fabric-api maven metadata..."
curl -sf "$BASE_MAVEN/net/fabricmc/fabric-api/fabric-api/maven-metadata.xml" -o "$DATA_DIR/fabric-api-maven.xml"

echo "Fetching legacy fabric maven metadata..."
curl -sf "$BASE_MAVEN/net/fabricmc/fabric/maven-metadata.xml" -o "$DATA_DIR/fabric-legacy-maven.xml"

echo "Fetching fabric-api version data from Modrinth..."
MODRINTH_URL="https://api.modrinth.com/v2/project/fabric-api/version"
modrinth_offset=0
while true; do
	curl -sf "${MODRINTH_URL}?limit=100&offset=${modrinth_offset}" > "$DATA_DIR/fabric-api-modrinth.tmp"
	jq -c '.[] | {v: .version_number, g: .game_versions}' "$DATA_DIR/fabric-api-modrinth.tmp"
	count=$(jq 'length' "$DATA_DIR/fabric-api-modrinth.tmp")
	(( count < 100 )) && break
	modrinth_offset=$((modrinth_offset + count))
done | jq -s '.' > "$DATA_DIR/fabric-api-modrinth.json"
rm -f "$DATA_DIR/fabric-api-modrinth.tmp"

echo "Fetching fabric-loom maven metadata..."
curl -sf "$BASE_MAVEN/net/fabricmc/fabric-loom/maven-metadata.xml" -o "$DATA_DIR/fabric-loom-maven.xml"

echo "Done. Files written to $DATA_DIR/"
echo "Latest game version: $(jq -r '.[0].version' "$DATA_DIR/game.json")"
echo "Latest loader version: $(jq -r '.[0].version' "$DATA_DIR/loader.json")"
echo "Latest loom version: $(xmllint --xpath 'string(/metadata/versioning/release)' "$DATA_DIR/fabric-loom-maven.xml")"
