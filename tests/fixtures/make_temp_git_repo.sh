#!/usr/bin/env bash
set -euo pipefail
# Create a temporary Git repository for tests and print its path.
# Usage:
#   repo_dir=$(./tests/fixtures/make_temp_git_repo.sh)
#   pushd "$repo_dir" && echo "hello" > file.txt && git add . && git commit -m "test" && popd

# Create a temp dir
TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t tmp)

# Initialize repo
cd "$TMPDIR"

git init -q

git config user.name "Test User"
git config user.email "test@example.com"

echo "Temporary test repo created at: $TMPDIR" 1>&2

# Output the path for caller usage
echo "$TMPDIR"
