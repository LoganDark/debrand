#!/bin/zsh
# build-all.zsh — build every mapped debrand change and dedupe the artifacts.
# For each change in `mapped+::master ~ unmapped` (oldest first), check out a
# fresh working copy on top of it, run `./gradlew build`, then abandon the
# working copy. Finally, dedupe all collected jars from build/libs into
# build/deduped.
set -euo pipefail

if [[ $# -ne 0 ]]; then
	print -ru2 -- "Usage: ${0:t}"
	print -ru2 -- "  Build every mapped debrand change and dedupe the artifacts."
	exit 2
fi

# Operate from the project root regardless of where the script is invoked from
# (this file lives at scripts/debrand/ — two levels below the root).
root="${0:A:h:h:h}"
cd -- "$root"

print -ru2 -- "${0:t}: cleaning build/libs and build/deduped"
rm -rf build/libs build/deduped

changeids=("${(@f)$(jj log -r 'mapped+::master ~ unmapped' --no-graph -T 'change_id ++ "\n"' --reversed)}")

print -ru2 -- "${0:t}: building ${#changeids} change(s)"

for changeid in "${changeids[@]}"; do
	print -ru2 -- "${0:t}: building $changeid"
	jj new "$changeid"
	./gradlew build
	jj abandon
done

print -ru2 -- "${0:t}: deduping build/libs -> build/deduped"
tsx ../fabric-dedupe/src/index.ts build/libs -o build/deduped

print -ru2 -- "${0:t}: done"
