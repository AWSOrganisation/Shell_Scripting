#!/bin/bash

set -euo pipefail

API_URL="https://api.github.com"

USERNAME="${username:?Set username}"
TOKEN="${token:?Set token}"

REPO_OWNER="$1"
REPO_NAME="$2"

github_api_get() {
    curl -s \
      -u "${USERNAME}:${TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      "${API_URL}/$1"
}

list_users_with_read_access() {
    local endpoint="repos/${REPO_OWNER}/${REPO_NAME}/collaborators"
    local response collaborators

    response="$(github_api_get "$endpoint")"

    collaborators="$(
      echo "$response" |
      jq -r '
        if type == "array" then
          .[] |
          select(type == "object") |
          select(.permissions | type == "object") |
          select(.permissions.pull == true) |
          .login
        else
          empty
        end
      '
    )"

    if [[ -z "$collaborators" ]]; then
        echo "No users with read access found for ${REPO_OWNER}/${REPO_NAME}."
    else
        echo "Users with read access to ${REPO_OWNER}/${REPO_NAME}:"
        echo "$collaborators"
    fi
}

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <repo-owner> <repo-name>"
    exit 1
fi

echo "Listing users with read access to ${REPO_OWNER}/${REPO_NAME}..."
list_users_with_read_access
