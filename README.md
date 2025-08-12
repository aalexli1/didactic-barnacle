# didactic-barnacle

## Repo Access Validation

Use the included tool to verify that your credentials allow cloning and pushing to a Git remote. It performs a safe, short‑lived push on a temporary branch and cleans it up by default.

- Clone only:
  - `python tools/validate_repo_access.py --remote https://github.com/owner/repo.git --no-push`
- Full check (clone + commit + push):
  - `python tools/validate_repo_access.py --remote https://github.com/owner/repo.git`
- Private HTTPS repos: provide a token via `GIT_AUTH_TOKEN` env var:
  - `GIT_AUTH_TOKEN=ghp_xxx python tools/validate_repo_access.py --remote https://github.com/owner/repo.git`
- SSH remotes work with your configured SSH agent:
  - `python tools/validate_repo_access.py --remote git@github.com:owner/repo.git`

Flags:
- `--keep`: keep the remote branch instead of deleting it.
- `--branch-prefix`: change the temporary branch prefix (default: `access-check`).

The tool only creates a small marker file under `.access-check/` on its temporary branch. No existing branches are modified.
