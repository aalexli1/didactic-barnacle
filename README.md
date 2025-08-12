# didactic-barnacle

## Repository Validation

To validate access to a Git remote without embedding any Git internals in this
source tree, use `scripts/validate_repo_access.sh`:

```
scripts/validate_repo_access.sh <git_remote_url> [ref]
```

See `docs/REPO_VALIDATION.md` for details. Historical embedded bare repos and
`.git` directories have been removed to keep the tree clean.
