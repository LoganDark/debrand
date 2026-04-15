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

jj -R "$REPO_DIR" new -A @ -m "$GAME_VERSION"
jj -R "$REPO_DIR" b c "$BOOKMARK"
"$SCRIPTS_DIR/template/set-version.sh" "$GAME_VERSION"
