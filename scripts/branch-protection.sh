#! /usr/bin/env bash
# branch-protection.sh
# this script goes over all repos in a codeberg $ORG and ensures $RULES are set
# usage:
# 	branch-protection
# 	TOKEN='your-codeberg-token' branch-protection
# 	TOKEN='your-codeberg-token' branch-protection 'repo'

set -eo pipefail

# shellcheck source=scripts/common.sh
source scripts/common.sh

RULES='{
	"rule_name": "main",
	"branch_name": "main",
	"enable_push": true,
	"enable_push_whitelist": false,
	"push_whitelist_deploy_keys": false,
	"enable_merge_whitelist": false,
	"enable_status_check": true,
	"status_check_contexts": ["*"],
	"required_approvals": 1,
	"enable_approvals_whitelist": false,
	"block_on_rejected_reviews": false,
	"block_on_official_review_requests": false,
	"block_on_outdated_branch": false,
	"dismiss_stale_approvals": false,
	"ignore_stale_approvals": false,
	"require_signed_commits": false,
	"protected_file_patterns": "",
	"unprotected_file_patterns": "",
	"apply_to_admins": false
}'

set_rules() {
	local repo="$1"
	local name="$2"

	if [[ -n "$2" ]]; then
		_="$(api 'PATCH' "repos/$ORG/$repo/branch_protections/$name" '.' "$RULES")"
	else
		_="$(api 'POST' "repos/$ORG/$repo/branch_protections" '.' "$RULES")"
	fi
}

ensure_rules() {
	local repo="$1"
  local rules

	echo " - $repo"

	rules="$(api 'GET' "repos/$ORG/$repo/branch_protections" '.')"

	if [[ -n "$(echo "$rules" | jq -rc '.[]')" ]] && [[ "$(echo "$rules" | jq -e 'any(.[]; .rule_name == "main")')" = 'true' ]]; then
		confirm "${PREFIX}existing rules found. overwrite?" &&
			set_rules "$repo" 'main'
	else
		set_rules "$repo"
	fi
}

if [[ -n "$1" ]]; then
	ensure_rules "$1"
else
	readarray REPOS < <(api 'GET' "orgs/$ORG/repos" '.[].name')
	echo "repos fetched. checking"

	for repo in "${REPOS[@]}"; do
		repo=$(echo "$repo" | tr -d '\n')
		ensure_rules "$repo"
	done
fi

echo 'done :3'
