from pathlib import Path

from .utils import run, init_origin_with_commit, init_bare_repo, push_origin_to_bare


def test_clone_from_local_bare_repo(tmp_path: Path):
    # Arrange: create origin with a commit, and a bare remote mirroring it
    origin = init_origin_with_commit(tmp_path / "origin")
    bare = init_bare_repo(tmp_path / "remote.git")
    push_origin_to_bare(origin, bare)

    # Act: clone from bare into a new worktree
    clone_dir = tmp_path / "clone"
    run(["git", "clone", str(bare), str(clone_dir)])

    # Assert: cloned repo has expected file and branch
    readme = (clone_dir / "README.md").read_text()
    assert "hello from origin" in readme
    branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=clone_dir)
    assert branch == "main"

