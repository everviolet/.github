#! /usr/bin/env bash

set -eo pipefail

ORG='evergarden'
CODEBERG='https://codeberg.org'
API="$CODEBERG/api/v1"
DEPS=('curl' 'jq')
PREFIX='   '

confirm() {
	local msg="$1"
	echo -n "$msg [y/N] "

	local confirm
	read -r confirm
	[[ "${confirm,,}" = 'y' ]]
}

token_error() {
	echo 'set the TOKEN variable to a valid token with scopes:'
	printf " - %s: %s\n" 'organization' 'read' 'repository' 'write'
	echo "$CODEBERG/user/settings/applications"
	echo

	if [[ -f "${XDG_DATA_HOME:-"$HOME/.local/share"}/berg-cli/codeberg.org/TOKEN" ]]; then
		confirm 'berg token found. use that one?' &&
			TOKEN="$(<"$HOME/.local/share/berg-cli/TOKEN")" ||
			exit 1
	else
		exit 1
	fi

	echo
}

api() {
	local req="$1"
	local uri="$2"
	local pat="$3"
	local dat="$4"
	local res
	local msg

	res="$(curl -sX "$req" \
		"$API/$uri" \
		-H 'Accept: application/json' \
		-H 'Content-Type: application/json' \
		-H "Authorization: token $TOKEN" \
		-d "$dat")"

	msg="$(echo "$res" | jq -sc '.message' 2>/dev/null || echo 'null')"
	if [[ "$msg" != 'null' ]]; then
		echo "${PREFIX}error: $msg"
	fi

	echo "$res" | jq -rc "$pat"
}

if [[ -z "$TOKEN" ]]; then token_error; fi

for dep in "${DEPS[@]}"; do
	if ! command -v "$dep" >/dev/null; then
		echo "you need $dep !!!"
		exit 1
	fi
done
