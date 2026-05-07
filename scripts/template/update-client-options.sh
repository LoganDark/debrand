#!/usr/bin/env zsh
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

# Create an empty child of @ so the client run's modifications can be squashed
# back into the original revision without rewriting its descendants' diffs.
jj -R "$REPO_DIR" new

# Launch the game
"$REPO_DIR/gradlew" -p "$REPO_DIR" runClient

# Show what changed
echo ""
echo "Changes to options.txt:"
jj -R "$REPO_DIR" diff run/options.txt

# Offer to edit the file before squashing
echo -n "Open run/options.txt in nano? [y/N] "
read -r answer
if [[ "$answer" == [yY] ]]; then
	nano "$REPO_DIR/run/options.txt"
fi

# Squash changes into the original revision, preserving descendants
jj -R "$REPO_DIR" squash --restore-descendants

# Land back on the revision we just updated (the empty squash leftover
# auto-disappears since it's empty and undescribed).
jj -R "$REPO_DIR" edit '@-'

echo "Done. Descendants restored."
