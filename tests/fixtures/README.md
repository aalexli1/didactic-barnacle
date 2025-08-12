# Test Fixtures: Temporary Git Repositories

This project previously included a fully committed demo Git repository under `repo-access-demo/`. That has been removed to avoid bloating the repository and accidentally shipping Git internals or hook templates.

Use temporary repositories during tests instead:

- `make_temp_git_repo.sh`: Creates a clean, temporary Git repository and prints its path. Caller can then perform test operations (commit, branch, push to a temp bare remote, etc.). The repository is placed in the system temp directory and can be cleaned up by the test harness.

## Quick Start

```bash
# Create a temp repo and capture the path
repo_dir=$(./tests/fixtures/make_temp_git_repo.sh)

# Work in the repo
pushd "$repo_dir"
echo "hello" > file.txt
git add file.txt
git commit -m "Add file"
popd
```

## Creating a Temporary Bare Remote (optional)

```bash
bare_dir=$(mktemp -d)
GIT_DIR="$bare_dir" git init --bare -q

# Add as remote and push
pushd "$repo_dir"
git branch -M main
git remote add origin "$bare_dir"
git push -u origin main
popd

echo "Bare remote at: $bare_dir"
```

## Rationale

- Avoids committing entire Git repos or hook templates.
- Keeps tests hermetic and disposable.
- Works on CI and local environments with standard Git installed.
