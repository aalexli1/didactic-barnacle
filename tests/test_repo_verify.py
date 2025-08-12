from pathlib import Path

from .utils import run, init_origin_with_commit, init_bare_repo, push_origin_to_bare


def test_verify_access_with_ls_remote(tmp_path: Path):
    # Arrange: create a bare remote with a main branch
    origin = init_origin_with_commit(tmp_path / "origin")
    bare = init_bare_repo(tmp_path / "remote.git")
    push_origin_to_bare(origin, bare)

    # Act: query remote refs
    out = run(["git", "ls-remote", str(bare)])

    # Assert: output contains a 40-char sha and refs/heads/main
    lines = [l for l in out.splitlines() if l.strip()]
    assert any(line.endswith("refs/heads/main") for line in lines)
    # basic sanity: first token is a 40-hex sha
    sha = lines[0].split()[0]
    assert len(sha) == 40 and all(c in "0123456789abcdef" for c in sha.lower())

