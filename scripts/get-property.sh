#!/bin/zsh
# get-property.sh — read a property value from a properties file.
# Prints everything after the first '=' on the first line whose key
# (with optional surrounding whitespace) matches <name>, stripped of
# leading whitespace and with no trailing newline.
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
	print -ru2 -- "Usage: ${0:t} <name> [file=gradle.properties]"
	print -ru2 -- "  Print the value of property <name> from [file]."
	exit 2
fi

name="$1"
file="${2:-gradle.properties}"

if [[ ! -f "$file" ]]; then
	print -ru2 -- "${0:t}: file not found: $file"
	exit 1
fi

while IFS= read -r line || [[ -n "$line" ]]; do
	key="${line%%=*}"
	[[ "$key" == "$line" ]] && continue   # no '=' on this line
	# trim surrounding whitespace from the key
	key="${key#"${key%%[![:space:]]*}"}"
	key="${key%"${key##*[![:space:]]}"}"
	if [[ "$key" == "$name" ]]; then
		value="${line#*=}"
		# strip leading whitespace from the value
		value="${value#"${value%%[![:space:]]*}"}"
		print -rn -- "$value"
		exit 0
	fi
done < "$file"

print -ru2 -- "${0:t}: property not found: $name"
exit 1
