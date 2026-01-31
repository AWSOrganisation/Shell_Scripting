#!/bin/bash

set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------

API_URL="https://api.github.com"

# These must be exported or set before running the script
USERNAME="${username:?GitHub username not set}"
TOKEN="${token:?GitHub token not set}"

# Repository information (passed as arguments)
REPO_OWNER="$1"
REPO_NAME="$2"

# -----------------------------
# Functions
# -----------------------------

# Make a GET request to the GitHub API
github_api_get() {
    local endpoint="$1"
    curl -s -u "${USERNAME}:${TOKEN}" "${API_URL}/${endpoint}"
}

# List users with read (pull) access
list_users_with_read_access() {
    local endpoint="repos/${REPO_OWNER}/${REPO_NAME}/collaborators"
    local response collaborators

    response="$(github_api_get "$endpoint")"

    # Check for GitHub API error message
    if echo "$response" | jq -e '.message?' >/dev/null; then
        echo "GitHub API error:"
        echo "$response" | jq -r '.message'
        exit 1
    fi

    collaborators="$(
        echo "$response" |
        jq -r '
            .[]? |
            select(.permissions?.pull == true) |
            .login
        '
    )"

    if [[ -z "$collaborators" ]]; then
        echo "No users with read access found for ${REPO_OWNER}/${REPO_NAME}."
    else
        echo "Users with read access to ${REPO_OWNER}/${REPO_NAME}:"
        echo "$collaborators"
    fi
}

# -----------------------------
# Main
# -----------------------------

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <repo-owner> <repo-name>"
    exit 1
fi

echo "Listing users with read access to ${REPO_OWNER}/${REPO_NAME}..."
list_users_with_read_access

