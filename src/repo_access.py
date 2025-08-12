import os
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from typing import Optional, Tuple


@dataclass
class RepoCheckResult:
    ok: bool
    message: str


def _run_git(args, cwd: Optional[str] = None, timeout: int = 20) -> Tuple[int, str, str]:
    """Run a git command and return (code, stdout, stderr)."""
    proc = subprocess.run(
        ["git", *args],
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=timeout,
    )
    return proc.returncode, proc.stdout, proc.stderr


def can_read_repo(repo_url: str) -> RepoCheckResult:
    """Verify that the repository is readable using `git ls-remote`."""
    try:
        code, out, err = _run_git(["ls-remote", "--heads", "--exit-code", repo_url])
        if code == 0:
            return RepoCheckResult(True, "Read access OK")
        return RepoCheckResult(False, f"Read access failed: {err.strip() or out.strip()}")
    except subprocess.TimeoutExpired:
        return RepoCheckResult(False, "Read check timed out")
    except FileNotFoundError:
        return RepoCheckResult(False, "git not found in PATH")


def _ensure_user_identity(cwd: str) -> None:
    # Set a deterministic identity for temporary test repos.
    _run_git(["config", "user.name", "Repo Access Bot"], cwd=cwd)
    _run_git(["config", "user.email", "bot@example.local"], cwd=cwd)


def _init_bare_repo(path: str) -> None:
    os.makedirs(path, exist_ok=True)
    _run_git(["init", "--bare", path])


def _seed_and_push_initial(remote_path: str, branch: str = "main") -> None:
    with tempfile.TemporaryDirectory(prefix="repo-access-work-") as work:
        _run_git(["init"], cwd=work)
        _ensure_user_identity(work)
        with open(os.path.join(work, "README.md"), "w", encoding="utf-8") as f:
            f.write("Temporary repo for access validation.\n")
        _run_git(["add", "README.md"], cwd=work)
        _run_git(["commit", "-m", "seed"], cwd=work)
        _run_git(["branch", "-M", branch], cwd=work)
        _run_git(["remote", "add", "origin", remote_path], cwd=work)
        _run_git(["push", "-u", "origin", branch], cwd=work)


def can_push_repo(repo_url: str) -> RepoCheckResult:
    """Attempt to create a temporary branch and push to the repo.

    For safety, only attempts push to local paths (filesystem URLs or paths).
    """
    is_local = os.path.isdir(repo_url) or repo_url.startswith("file://")
    if not is_local:
        return RepoCheckResult(
            False,
            "Push check skipped: only local filesystem repos are allowed for this check",
        )

    # Normalize file:// URL to path for subprocess compatibility
    remote_path = repo_url
    if remote_path.startswith("file://"):
        remote_path = remote_path.replace("file://", "", 1)

    test_branch = "access-check/" + next(tempfile._get_candidate_names())
    try:
        with tempfile.TemporaryDirectory(prefix="repo-access-clone-") as clone_dir:
            # Clone or seed and then clone if empty
            try:
                # Try a normal clone first
                code, out, err = _run_git(["clone", remote_path, clone_dir])
                if code != 0:
                    # If clone fails because repo is empty, seed it
                    if "empty repository" in (err.lower() + out.lower()):
                        _seed_and_push_initial(remote_path)
                        # retry clone
                        code, out, err = _run_git(["clone", remote_path, clone_dir])
                if code != 0:
                    return RepoCheckResult(False, f"Clone failed: {err.strip() or out.strip()}")
            except subprocess.TimeoutExpired:
                return RepoCheckResult(False, "Clone timed out")

            _ensure_user_identity(clone_dir)
            # Make a tiny change
            path = os.path.join(clone_dir, "ACCESS_CHECK.txt")
            with open(path, "w", encoding="utf-8") as f:
                f.write("ok\n")
            _run_git(["add", "ACCESS_CHECK.txt"], cwd=clone_dir)
            code, out, err = _run_git(["commit", "-m", "repo access check"], cwd=clone_dir)
            if code != 0:
                return RepoCheckResult(False, f"Commit failed: {err.strip() or out.strip()}")

            # Create and push a temporary branch
            _run_git(["checkout", "-b", test_branch], cwd=clone_dir)
            code, out, err = _run_git(["push", "-u", "origin", test_branch], cwd=clone_dir)
            if code != 0:
                return RepoCheckResult(False, f"Push failed: {err.strip() or out.strip()}")

            # Optional cleanup: delete remote branch
            _run_git(["push", "origin", "--delete", test_branch], cwd=clone_dir)

        return RepoCheckResult(True, "Push access OK")
    except subprocess.TimeoutExpired:
        return RepoCheckResult(False, "Push check timed out")
    except FileNotFoundError:
        return RepoCheckResult(False, "git not found in PATH")


def self_test() -> RepoCheckResult:
    """Create a temporary bare repo and validate read and push against it."""
    base = tempfile.mkdtemp(prefix="repo-access-remote-")
    try:
        remote_dir = os.path.join(base, "remote.git")
        _init_bare_repo(remote_dir)
        # Seed with one commit so ls-remote has something to read
        _seed_and_push_initial(remote_dir)

        read = can_read_repo(remote_dir)
        if not read.ok:
            return RepoCheckResult(False, f"Self-test read failed: {read.message}")

        push = can_push_repo(remote_dir)
        if not push.ok:
            return RepoCheckResult(False, f"Self-test push failed: {push.message}")

        return RepoCheckResult(True, f"Self-test OK against {remote_dir}")
    finally:
        # Clean up the temporary remote
        shutil.rmtree(base, ignore_errors=True)

