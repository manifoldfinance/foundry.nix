#!/usr/bin/env bash

set -euo pipefail

# Workflow should set $GITHUB_TOKEN
#GITHUB_TOKEN=''
GITHUB_REPO='foundry'
GITHUB_ORG='foundry-rs'
#https://github.com/foundry-rs/foundry
get_last_page() {
	local url="$1"
	curl -sSf -I -H "Authorization: Bearer $GITHUB_TOKEN" \
		"$url" |
		grep -E '^link: ' |
		sed -e 's/^link:.*page=//g' -e 's/>.*$//g' || echo "1"
}

generate() {
	local url="$1"
	local file="$2"
	last_page="$(get_last_page "$url")"
	tmp="$(mktemp -d)"

	for i in $(seq 1 "$last_page"); do
		echo "page: $i"
		curl -sSf "$url?page=$i" | jq 'map({tag_name: .tag_name})' >"$tmp/$i.json"
	done

	if test "$last_page" -eq "1"; then
		cp -f "$tmp"/1.json "$file"
	else
		jq --compact-output -s 'add' "$tmp"/*.json >"$file"
	fi
	du -hs "$file"
}

# www/docs/static/releases.json
generate "https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/releases" "releases.json"
