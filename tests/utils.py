import subprocess
from pathlib import Path


def run(cmd, cwd=None):
    """Run a shell command and return (stdout).
    Raises CalledProcessError on failure.
    """
    result = subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return result.stdout.strip()


def init_origin_with_commit(path: Path, branch: str = "main") -> Path:
    """Initialize a non-bare git repo with an initial commit on `branch`."""
    path.mkdir(parents=True, exist_ok=True)
    run(["git", "init"], cwd=path)
    # Ensure user identity is set for committing
    run(["git", "config", "user.email", "test@example.com"], cwd=path)
    run(["git", "config", "user.name", "Test User"], cwd=path)

    # Create a file and commit
    (path / "README.md").write_text("hello from origin\n")
    run(["git", "add", "README.md"], cwd=path)
    run(["git", "commit", "-m", "chore: initial"], cwd=path)

    # Create/force branch name
    run(["git", "checkout", "-B", branch], cwd=path)
    return path


def init_bare_repo(path: Path) -> Path:
    """Initialize a bare git repo at path."""
    path.mkdir(parents=True, exist_ok=True)
    run(["git", "init", "--bare"], cwd=path)
    return path


def push_origin_to_bare(origin: Path, bare: Path, branch: str = "main", remote: str = "origin") -> None:
    """Add bare as remote and push the branch."""
    run(["git", "remote", "add", remote, str(bare)], cwd=origin)
    run(["git", "push", "-u", remote, f"HEAD:refs/heads/{branch}"] , cwd=origin)

