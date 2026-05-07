#!/usr/bin/env zsh
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

# Create an empty child of @ so the server run's modifications can be squashed
# back into the original revision without rewriting its descendants' diffs.
jj -R "$REPO_DIR" new

# Launch the server
"$REPO_DIR/gradlew" -p "$REPO_DIR" runServer

# Show what changed
echo ""
echo "Changes to server.properties:"
jj -R "$REPO_DIR" diff run_server/server.properties

# Offer to edit the file before squashing
echo -n "Open run_server/server.properties in nano? [y/N] "
read -r answer
if [[ "$answer" == [yY] ]]; then
	nano "$REPO_DIR/run_server/server.properties"
fi

# Squash changes into the original revision, preserving descendants
jj -R "$REPO_DIR" squash --restore-descendants

# Land back on the revision we just updated (the empty squash leftover
# auto-disappears since it's empty and undescribed).
jj -R "$REPO_DIR" edit '@-'

echo "Done. Descendants restored."
