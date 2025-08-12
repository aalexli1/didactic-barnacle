# didactic-barnacle

This repository previously included a demo Git repository under `repo-access-demo/` to validate repository access flows.
That embedded repository (including Git hook samples) has been removed based on code review feedback.

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
