#!/usr/bin/env zsh
# update-mappings.sh — bump yarn_mappings to the latest build for each mapped
# game version. For every change in `mapped+::unmapped-` (oldest first), create
# an empty child, edit gradle.properties, then squash it back in with
# --restore-descendants so the rest of the stack keeps its content.
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
changeids=("${(@f)$(jj -R "$REPO_DIR" --quiet log -r 'mapped+::unmapped-' --no-graph -T 'change_id ++ "\n"' --reversed)}")

for changeid in "${changeids[@]}"; do
	# Empty child of changeid; modifications squash straight back into it.
	jj -R "$REPO_DIR" --quiet new "$changeid"

	game_version=$("$SCRIPTS_DIR/get-property.sh" minecraft_version "$REPO_DIR/gradle.properties")
	old_yarn=$("$SCRIPTS_DIR/get-property.sh" yarn_mappings "$REPO_DIR/gradle.properties")
	yarn=$(zsh "$SCRIPTS_DIR/template/properties.sh" "$game_version" | grep '^yarn_mappings=' | cut -d= -f2)

	if [[ -z "$yarn" ]]; then
		echo "Skipped $game_version (no yarn available)"
	elif [[ "$old_yarn" == "$yarn" ]]; then
		echo "Skipped $game_version (already $yarn)"
	else
		"$SCRIPTS_DIR/set-property.sh" yarn_mappings "$yarn" "$REPO_DIR/gradle.properties"
		echo "Updated $game_version (from ${old_yarn:-<empty>} to $yarn)"
		jj -R "$REPO_DIR" --quiet squash --restore-descendants
	fi
done

# Return to the original working copy. The trailing empty commit auto-abandons.
jj -R "$REPO_DIR" --quiet edit "$original"

echo "Done. Yarn mappings updated across mapped+::unmapped-."
