# Repository Access Validation

This project previously embedded a bare Git repository (`repo-remote.git/`) and
checked in `.git` directories under `repo-verify/` and `repo-work/`. Those items
have been removed to avoid committing Git internals and binary object files.

Use the provided script to validate remote access without cloning or embedding
Git data:

- Script: `scripts/validate_repo_access.sh`
- Usage: `scripts/validate_repo_access.sh <git_remote_url> [ref]`

Examples:
- Validate that the remote is reachable: `scripts/validate_repo_access.sh git@github.com:org/repo.git`
- Validate a specific ref exists: `scripts/validate_repo_access.sh https://github.com/org/repo.git main`

Notes:
- Authentication is handled by your environment (SSH agent, credential helper) or URL.
- No bare repositories or `.git` internals are stored in this source tree.

