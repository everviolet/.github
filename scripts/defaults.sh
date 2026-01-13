#! /usr/bin/env bash
# defaults.sh
# this script goes over all repos in a codeberg $ORG and ensures $SETTINGS are set
# usage:
# 	defaults
# 	TOKEN='your-codeberg-token' defaults
# 	TOKEN='your-codeberg-token' defaults 'repo'

set -eo pipefail

# shellcheck source=scripts/common.sh
source scripts/common.sh

SETTINGS='{
	"allow_merge_commits": false,
	"allow_rebase": true,
	"allow_rebase_explicit": false,
	"allow_squash_merge": true,
	"allow_fast_forward_only_merge": false,
	"allow_manual_merge": true,
	"default_merge_style": "squash",
	"default_allow_maintainer_edit": true,
	"allow_rebase_update": true,
	"default_update_style": "rebase",
	"default_delete_branch_after_merge": true,
	"autodetect_manual_merge": false,
	"ignore_whitespace_conflicts": false,
	"has_pull_requests": true,
	"has_issues": true,
	"has_releases": true
}'

ensure_settings() {
	local repo="$1"

	echo " - $repo"

	api 'PATCH' "repos/$ORG/$repo" '.' "$SETTINGS" >/dev/null
}

if [[ -n "$1" ]]; then
	ensure_settings "$1"
else
	confirm 'do you really want to overwrite settings for ALL repos?' || exit 0
	confirm 'are you sure?' || exit 0
	confirm 'are you definitely sure?' || exit 0
	confirm 'are you definitely absolutely sure?' || exit 0
	confirm 'are you definitely absolutely 100% sure?' || exit 0

  echo
	readarray REPOS < <(api 'GET' "orgs/$ORG/repos" '.[].name')
	echo 'ok then'

	for repo in "${REPOS[@]}"; do
		repo="${repo%\n}"
		ensure_settings "$repo"
	done
fi
