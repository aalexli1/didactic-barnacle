# didactic-barnacle

Validate repository access — clone and push

- Script: `scripts/validate_repo_access.py`
- What it does: clones a remote into a temp dir, creates a test branch, commits a marker file, pushes the branch, and optionally deletes it.

Quick start

- Use current repo origin: `python3 scripts/validate_repo_access.py`
- Explicit remote: `python3 scripts/validate_repo_access.py --remote https://example.com/owner/repo.git`
- With HTTPS token: `python3 scripts/validate_repo_access.py --remote https://example.com/owner/repo.git --token $GITHUB_TOKEN`
- Cleanup remote branch after: add `--cleanup`
- Make cleanup failures fatal: add `--cleanup --strict`

Notes

- Reads tokens from `GIT_TOKEN`, `GITHUB_TOKEN`, `GITLAB_TOKEN`, or `BITBUCKET_TOKEN` if `--token` is omitted.
- For HTTPS auth, username defaults to `x-access-token` (override with `--username`).
- SSH remotes work if your local SSH agent/keys can access the repo.
