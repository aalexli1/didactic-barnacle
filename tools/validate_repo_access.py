#!/usr/bin/env python3
"""
Validate repository access by attempting a safe clone and push.

This tool clones a remote repository into a temporary directory, creates a
short-lived branch, commits a small marker file, and pushes the branch.
Optionally, it deletes the remote branch afterwards.

Usage:
  python tools/validate_repo_access.py --remote https://github.com/owner/repo.git
  GIT_AUTH_TOKEN=... python tools/validate_repo_access.py --remote https://github.com/owner/repo.git

Notes:
  - For HTTPS remotes, set GIT_AUTH_TOKEN if the repo is private.
  - For SSH remotes (git@...), ensure your SSH agent has the right key.
  - The commit touches only a small file under .access-check/ and uses its own branch.
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path
from typing import List


def run(cmd: List[str], cwd: Path | None = None, env: dict | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def sanitize_remote(remote: str) -> str:
    # Avoid printing tokens
    if "@" in remote and "http" in remote:
        try:
            # e.g. https://user:token@host/path
            prefix, rest = remote.split("://", 1)
            auth_and_host, *tail = rest.split("@", 1)
            host_part = tail[0] if tail else ""
            return f"{prefix}://***@{host_part}"
        except Exception:
            return "***"
    return remote


def inject_token(remote: str, token: str) -> str:
    if not token:
        return remote
    if remote.startswith("https://"):
        # Insert a neutral username to satisfy Basic auth scheme; avoid special chars in token
        return remote.replace("https://", f"https://oauth2:{token}@", 1)
    return remote


def main() -> int:
    parser = argparse.ArgumentParser(description="Clone and push a test commit to validate access")
    parser.add_argument("--remote", required=True, help="Remote repository URL (HTTPS or SSH)")
    parser.add_argument("--branch-prefix", default="access-check", help="Prefix for temporary branch name")
    parser.add_argument("--keep", action="store_true", help="Keep the remote branch (skip deletion)")
    parser.add_argument("--no-push", action="store_true", help="Only clone; skip committing/pushing")
    parser.add_argument("--name", default=os.environ.get("GIT_AUTHOR_NAME", "Access Check Bot"), help="Commit author name")
    parser.add_argument("--email", default=os.environ.get("GIT_AUTHOR_EMAIL", "access-check@example.com"), help="Commit author email")
    args = parser.parse_args()

    token = os.environ.get("GIT_AUTH_TOKEN", "")
    remote_for_clone = inject_token(args.remote, token)
    sanitized = sanitize_remote(remote_for_clone)

    # Quick git availability check
    try:
        proc = run(["git", "--version"])
        if proc.returncode != 0:
            print("git is not available:", proc.stderr.strip(), file=sys.stderr)
            return 2
    except FileNotFoundError:
        print("git is not installed in PATH", file=sys.stderr)
        return 2

    temp_dir = Path(tempfile.mkdtemp(prefix="repo-access-check-"))
    workdir = temp_dir / "repo"
    try:
        print(f"Cloning {sanitize_remote(args.remote)} ...")
        clone_cmd = ["git", "clone", "--depth=1", remote_for_clone, str(workdir)]
        proc = run(clone_cmd)
        if proc.returncode != 0:
            print("Clone failed. Remote:", sanitized, file=sys.stderr)
            print(proc.stderr.strip() or proc.stdout.strip(), file=sys.stderr)
            return 1

        print("Clone OK.")
        if args.no_push:
            return 0

        # Configure author
        cfg_name = run(["git", "config", "user.name", args.name], cwd=workdir)
        cfg_email = run(["git", "config", "user.email", args.email], cwd=workdir)
        if cfg_name.returncode != 0 or cfg_email.returncode != 0:
            print("Failed to set git author:", (cfg_name.stderr + cfg_email.stderr).strip(), file=sys.stderr)
            return 1

        # Create branch
        ts = time.strftime("%Y%m%d-%H%M%S", time.gmtime())
        branch = f"{args.branch_prefix}/{ts}-{uuid.uuid4().hex[:8]}"
        proc = run(["git", "checkout", "-b", branch], cwd=workdir)
        if proc.returncode != 0:
            print("Failed to create branch:", proc.stderr.strip(), file=sys.stderr)
            return 1

        # Create marker file
        marker_dir = workdir / ".access-check"
        marker_dir.mkdir(parents=True, exist_ok=True)
        marker_file = marker_dir / f"{branch.replace('/', '_')}.txt"
        marker_file.write_text(
            "This is a temporary access check commit.\n"
            f"Branch: {branch}\n"
            f"Time: {ts}Z\n"
            "It is safe to delete this branch.\n"
        )

        proc = run(["git", "add", str(marker_file.relative_to(workdir))], cwd=workdir)
        if proc.returncode != 0:
            print("Failed to add file:", proc.stderr.strip(), file=sys.stderr)
            return 1

        proc = run(["git", "commit", "-m", f"chore: access check {branch}"], cwd=workdir)
        if proc.returncode != 0:
            print("Commit failed:", proc.stderr.strip() or proc.stdout.strip(), file=sys.stderr)
            return 1

        # Push
        proc = run(["git", "push", "-u", "origin", branch], cwd=workdir)
        if proc.returncode != 0:
            print("Push failed:", proc.stderr.strip() or proc.stdout.strip(), file=sys.stderr)
            return 1
        print(f"Push OK. Remote branch created: {branch}")

        # Try to delete remote branch unless --keep
        if not args.keep:
            proc = run(["git", "push", "origin", "--delete", branch], cwd=workdir)
            if proc.returncode == 0:
                print("Cleanup OK. Remote branch removed.")
            else:
                print("Cleanup skipped (failed to delete remote branch).", file=sys.stderr)
        else:
            print("Keeping remote branch as requested (--keep).")

        return 0
    finally:
        try:
            shutil.rmtree(temp_dir)
        except Exception:
            pass


if __name__ == "__main__":
    sys.exit(main())

