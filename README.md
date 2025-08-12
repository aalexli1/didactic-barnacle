# didactic-barnacle

## Repository Access Validation

This project previously committed a full bare Git repository (`remote-repo.git`) and a working repository (`working-repo`) for validation. These have been removed to avoid committing Git internals and hooks. Validation now uses real Git operations against dynamically created, throwaway repositories.

- How to run a self-test (creates and cleans up temp repos):
  - `python3 scripts/validate_repo_access.py`

- Validate read (ls-remote) against a specific repo URL or path:
  - `python3 scripts/validate_repo_access.py --repo-url <URL-or-path>`

- Validate push against a local bare repo (safe, only for filesystem paths):
  - `python3 scripts/validate_repo_access.py --repo-url /path/to/bare.git --check-push`

The implementation lives in `src/repo_access.py` and never relies on checked-in Git repositories.

## Git Hooks Policy

Do not commit Git hooks to source control. If you need hooks for local development, add setup instructions instead, for example:

```
# Example (optional) developer setup
cp -n .hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

No hooks are required to run repository access validation.
