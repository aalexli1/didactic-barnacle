# didactic-barnacle

This repository previously included a demo Git repository under `repo-access-demo/` to validate repository access flows.
That embedded repository (including Git hook samples) has been removed based on code review feedback.

## Removed Artifacts
- `repo-access-demo/` and `repo-access-demo/origin.git/`: fully embedded Git repo and its hook samples were removed.
- `repo-access-demo/work-repo`: unclear-purpose placeholder file removed. If needed in the future, document its role and add it back under a clear test fixture.

These paths are now listed in `.gitignore` to avoid accidental reintroduction.

Use temporary repositories during testing instead:

- Script: `tests/fixtures/make_temp_git_repo.sh` creates a clean temporary Git repo and prints its path.
- Docs: see `tests/fixtures/README.md` for quick start and rationale.

Example:

```
repo_dir=$(./tests/fixtures/make_temp_git_repo.sh)
pushd "$repo_dir"
echo "hello" > file.txt
git add file.txt
git commit -m "Add file"
popd
```
