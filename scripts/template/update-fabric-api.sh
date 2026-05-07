#!/usr/bin/env zsh
# update-fabric-api.sh — bump fabric_api_version to the latest available for
# each game version. For every change in `mapped+::master ~ unmapped` (oldest
# first), create an empty child, edit gradle.properties, then squash it back in
# with --restore-descendants so the rest of the stack keeps its content.
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

# Save current working copy revision so we can return to it at the end.
original=$(jj -R "$REPO_DIR" log -r '@' --no-graph -T 'change_id')

# Collect change ids up front. jj change ids are stable across the rebases that
# `squash --restore-descendants` performs, so this fixed list stays valid for
# the whole run — unlike re-querying children(), which would also pick up the
# empty commits we create and recurse forever.
changeids=("${(@f)$(jj -R "$REPO_DIR" --quiet log -r 'mapped+::master ~ unmapped' --no-graph -T 'change_id ++ "\n"' --reversed)}")

for changeid in "${changeids[@]}"; do
	# Empty child of changeid; modifications squash straight back into it.
	jj -R "$REPO_DIR" --quiet new "$changeid"

	game_version=$("$SCRIPTS_DIR/get-property.sh" minecraft_version "$REPO_DIR/gradle.properties")
	old_api=$("$SCRIPTS_DIR/get-property.sh" fabric_api_version "$REPO_DIR/gradle.properties")
	api=$(zsh "$SCRIPTS_DIR/template/properties.sh" "$game_version" | grep '^fabric_api_version=' | cut -d= -f2)

	if [[ -z "$api" ]]; then
		echo "Skipped $game_version (no Fabric API available)"
	elif [[ "$old_api" == "$api" ]]; then
		echo "Skipped $game_version (already $api)"
	else
		"$SCRIPTS_DIR/set-property.sh" fabric_api_version "$api" "$REPO_DIR/gradle.properties"
		echo "Updated $game_version (from ${old_api:-<empty>} to $api)"
		jj -R "$REPO_DIR" --quiet squash --restore-descendants
	fi
done

# Return to the original working copy. The trailing empty commit auto-abandons.
jj -R "$REPO_DIR" --quiet edit "$original"

echo "Done. Fabric API version updated across mapped+::master ~ unmapped."
