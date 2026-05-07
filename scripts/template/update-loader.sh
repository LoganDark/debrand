#!/usr/bin/env zsh
# update-loader.sh — set loader_version to the latest stable across every
# version. loader_version is game-version-independent, so this walks the whole
# chain `mapped+::master ~ unmapped`. For each change (oldest first) it creates
# an empty child, edits gradle.properties, then squashes it back in with
# --restore-descendants so the rest of the stack keeps its content.
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

loader_version=$(zsh "$SCRIPTS_DIR/template/properties.sh" | grep '^loader_version=' | cut -d= -f2)

if [[ -z "$loader_version" ]]; then
	echo "Error: Could not determine loader version." >&2
	exit 1
fi

echo "Latest stable loader: $loader_version"

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

	label=$("$SCRIPTS_DIR/get-property.sh" minecraft_version "$REPO_DIR/gradle.properties")
	old_loader=$("$SCRIPTS_DIR/get-property.sh" loader_version "$REPO_DIR/gradle.properties")

	if [[ "$old_loader" == "$loader_version" ]]; then
		echo "Skipped ${label:-$changeid} (already $loader_version)"
	else
		"$SCRIPTS_DIR/set-property.sh" loader_version "$loader_version" "$REPO_DIR/gradle.properties"
		echo "Updated ${label:-$changeid} (from ${old_loader:-<empty>} to $loader_version)"
		jj -R "$REPO_DIR" --quiet squash --restore-descendants
	fi
done

# Return to the original working copy. The trailing empty commit auto-abandons.
jj -R "$REPO_DIR" --quiet edit "$original"

echo "Done. Loader version updated to $loader_version across mapped+::master ~ unmapped."
