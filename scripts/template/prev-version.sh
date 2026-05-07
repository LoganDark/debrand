#!/usr/bin/env zsh
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

if [[ $# -lt 1 || $# -gt 2 ]]; then
	echo "Usage: $0 <game-version> [bookmark]" >&2
	exit 1
fi

GAME_VERSION="$1"
BOOKMARK="${2:-$GAME_VERSION}"

# Save current revision's change ID and commit ID
changeid=$(jj -R "$REPO_DIR" log -r '@' --no-graph -T 'change_id')
commitid=$(jj -R "$REPO_DIR" log -r '@' --no-graph -T 'commit_id')

# Insert new revision before current
jj -R "$REPO_DIR" new -B @ -m "$GAME_VERSION"
jj -R "$REPO_DIR" b c "$BOOKMARK"
jj -R "$REPO_DIR" restore --from "$commitid"
"$SCRIPTS_DIR/template/set-version.sh" "$GAME_VERSION"

# Restore the original revision from its old commit ID
jj -R "$REPO_DIR" restore --from "$commitid" --to "$changeid"
