#!/usr/bin/env zsh
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

GAME_VERSION="${1:-}"

for f in loader.json fabric-loom-maven.xml; do
	if [[ ! -f "$DATA_DIR/$f" ]]; then
		echo "Error: $f not found. Run fetch-data.sh first." >&2
		exit 1
	fi
done

if [[ -n "$GAME_VERSION" ]]; then
	for f in game.json yarn.json fabric-api-maven.xml fabric-legacy-maven.xml; do
		if [[ ! -f "$DATA_DIR/$f" ]]; then
			echo "Error: $f not found. Run fetch-data.sh first." >&2
			exit 1
		fi
	done

	# Validate game version exists
	if ! jq -e --arg gv "$GAME_VERSION" 'any(.[]; .version == $gv)' "$DATA_DIR/game.json" >/dev/null 2>&1; then
		echo "Error: Game version '$GAME_VERSION' not found. Try running fetch-data.sh to update." >&2
		exit 1
	fi

	echo "minecraft_version=$GAME_VERSION"

	# Yarn: latest build for this game version (omit if none, e.g. snapshots)
	yarn_mappings=$(jq -r --arg gv "$GAME_VERSION" \
		'[.[] | select(.gameVersion == $gv)] | .[0].version // empty' \
		"$DATA_DIR/yarn.json")
	[[ -n "$yarn_mappings" ]] && echo "yarn_mappings=$yarn_mappings"
fi

# Loader: latest stable
loader_version=$(jq -r '[.[] | select(.stable)] | .[0].version' "$DATA_DIR/loader.json")

if [[ -z "$loader_version" || "$loader_version" == "null" ]]; then
	echo "Error: No stable loader version found. Try running fetch-data.sh to update." >&2
	exit 1
fi

echo "loader_version=$loader_version"

# Loom: latest non-alpha version from maven metadata
loom_version=$(grep '<version>' "$DATA_DIR/fabric-loom-maven.xml" \
	| sed 's/.*<version>\(.*\)<\/version>.*/\1/' \
	| grep -v 'alpha' \
	| tail -1)

if [[ -z "$loom_version" ]]; then
	echo "Error: No loom version found. Try running fetch-data.sh to update." >&2
	exit 1
fi

echo "loom_version=$loom_version"

# Fabric API: find the latest version that supports this game version.
# Prefer Modrinth data (has accurate game_versions metadata), fall back to Maven suffix matching.
# Modrinth results are filtered against Maven to exclude phantom versions.
if [[ -n "$GAME_VERSION" ]]; then
	fabric_api_version=""

	# Build set of all versions that exist in Maven (both new fabric-api and legacy fabric artifacts)
	all_maven_versions=$(grep '<version>' "$DATA_DIR/fabric-api-maven.xml" "$DATA_DIR/fabric-legacy-maven.xml" \
		| sed 's/.*<version>\(.*\)<\/version>.*/\1/')

	if [[ -f "$DATA_DIR/fabric-api-modrinth.json" ]]; then
		# Get all Modrinth versions for this game version, then pick first one that exists in Maven
		modrinth_candidates=$(jq -r --arg gv "$GAME_VERSION" \
			'[.[] | select(.g | index($gv))] | .[].v' \
			"$DATA_DIR/fabric-api-modrinth.json")

		while IFS= read -r candidate; do
			[[ -z "$candidate" ]] && continue
			if echo "$all_maven_versions" | grep -qxF "$candidate"; then
				fabric_api_version="$candidate"
				break
			fi
		done <<< "$modrinth_candidates"
	fi

	if [[ -z "$fabric_api_version" ]]; then
		# Fall back to Maven suffix matching
		if [[ "$GAME_VERSION" == *-snapshot-* ]]; then
			api_suffix="${GAME_VERSION%%-snapshot-*}"
		else
			api_suffix="$GAME_VERSION"
		fi

		all_api_versions=$(grep '<version>' "$DATA_DIR/fabric-api-maven.xml" \
			| sed 's/.*<version>\(.*\)<\/version>.*/\1/')

		fabric_api_version=$(echo "$all_api_versions" | { grep "+${api_suffix}\$" || true; } | tail -1)
		if [[ -z "$fabric_api_version" && "$api_suffix" == *.* ]]; then
			api_suffix="${api_suffix%.*}"
			fabric_api_version=$(echo "$all_api_versions" | { grep "+${api_suffix}\$" || true; } | tail -1)
		fi
	fi

	if [[ -z "$fabric_api_version" ]]; then
		echo "Error: No Fabric API version found for '$GAME_VERSION'. Try running fetch-data.sh to update." >&2
		exit 1
	fi

	echo ""
	echo "# Fabric API"
	echo "fabric_api_version=$fabric_api_version"
fi
