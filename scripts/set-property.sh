#!/bin/zsh
# set-property.sh — set a property value in a properties file.
# Replaces everything after the first '=' on the first line whose key
# (with optional surrounding whitespace) matches <name>.
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
	print -ru2 -- "Usage: ${0:t} <name> <value> [file=gradle.properties]"
	print -ru2 -- "  Set property <name> to <value> in [file]."
	exit 2
fi

name="$1"
value="$2"
file="${3:-gradle.properties}"

if [[ ! -f "$file" ]]; then
	print -ru2 -- "${0:t}: file not found: $file"
	exit 1
fi

if [[ "$file" == */* ]]; then
	dir="${file%/*}"
else
	dir="."
fi

# Write to a temp file in the same directory, then atomically rename it over
# the original — a crash mid-write leaves the original intact, not truncated.
tmp="$(mktemp "$dir/.${0:t}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

found=0
while IFS= read -r line || [[ -n "$line" ]]; do
	if (( ! found )); then
		key="${line%%=*}"
		if [[ "$key" != "$line" ]]; then
			# trim surrounding whitespace from the key
			tkey="${key#"${key%%[![:space:]]*}"}"
			tkey="${tkey%"${tkey##*[![:space:]]}"}"
			if [[ "$tkey" == "$name" ]]; then
				line="${key}=${value}"
				found=1
			fi
		fi
	fi
	print -r -- "$line" >> "$tmp"
done < "$file"

if (( ! found )); then
	print -ru2 -- "${0:t}: property not found: $name"
	exit 1
fi

chmod --reference="$file" "$tmp"
mv -- "$tmp" "$file"
trap - EXIT

print -ru2 -- "${0:t}: set $name in $file"
