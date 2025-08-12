#!/usr/bin/env python3
"""
Validate repository access by cloning a remote, creating a temporary branch,
pushing a commit, and optionally cleaning up the remote branch.

Usage examples:
  scripts/validate_repo_access.py                       # uses current repo's origin
  scripts/validate_repo_access.py --remote https://...  # explicit remote
  scripts/validate_repo_access.py --token $GITHUB_TOKEN # HTTPS token auth
  scripts/validate_repo_access.py --cleanup             # delete test branch after

Supported auth:
- HTTPS: provide --token (and optional --username, defaults to x-access-token)
- SSH: relies on local SSH agent/keys; no flags required
"""

from __future__ import annotations

import argparse
import os
import random
import string
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from typing import Dict, List, Optional
from urllib.parse import urlsplit, urlunsplit, quote


def run(cmd: List[str], cwd: Optional[str] = None, env: Optional[Dict[str, str]] = None) -> str:
    """Run a command and return stdout, raising with helpful context on failure."""
    base_env = os.environ.copy()
    base_env.update({
        # Ensure git never prompts for interactive credentials
        "GIT_TERMINAL_PROMPT": "0",
    })
    if env:
        base_env.update(env)
    try:
        res = subprocess.run(
            cmd,
            cwd=cwd,
            env=base_env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=True,
        )
        return res.stdout
    except subprocess.CalledProcessError as e:
        out = e.stdout or ""
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{out}") from e


def mask_token_in_url(url: str) -> str:
    try:
        parts = urlsplit(url)
        if parts.username or parts.password:
            return urlunsplit((parts.scheme, parts.hostname or "", parts.path, parts.query, parts.fragment))
    except Exception:
        pass
    return url


def inject_basic_auth(url: str, username: str, token: str) -> str:
    parts = urlsplit(url)
    if parts.scheme not in ("http", "https"):
        return url  # non-HTTP(S) transports (e.g., SSH) keep as-is
    quoted_user = quote(username or "", safe="")
    quoted_pass = quote(token or "", safe="")
    netloc = parts.netloc
    # Drop existing userinfo if any
    if "@" in netloc:
        netloc = netloc.split("@", 1)[-1]
    return urlunsplit((parts.scheme, f"{quoted_user}:{quoted_pass}@{netloc}", parts.path, parts.query, parts.fragment))


def unique_branch_name(prefix: str = "access-check") -> str:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    rand = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
    return f"{prefix}/{stamp}-{rand}"


def resolve_origin_url_from_cwd() -> Optional[str]:
    try:
        out = run(["git", "remote", "get-url", "origin"], cwd=os.getcwd())
        return out.strip() or None
    except Exception:
        return None


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Validate clone and push access to a Git remote.")
    parser.add_argument("--remote", help="Remote URL to test. Defaults to 'origin' of current repo.")
    parser.add_argument("--token", help="HTTPS token/password for basic auth. Also reads GIT_TOKEN/GITHUB_TOKEN/GITLAB_TOKEN.")
    parser.add_argument("--username", default="x-access-token", help="Username for HTTPS basic auth (default: x-access-token).")
    parser.add_argument("--branch", help="Branch name to create (default: generated unique name).")
    parser.add_argument("--prefix", default="access-check", help="Prefix for generated branch name.")
    parser.add_argument("--cleanup", action="store_true", help="Delete the remote test branch after validation.")
    args = parser.parse_args(argv)

    remote = args.remote or os.environ.get("REMOTE_URL") or resolve_origin_url_from_cwd()
    if not remote:
        print("Error: Could not determine remote. Provide --remote or configure 'origin'.", file=sys.stderr)
        return 2

    token = (
        args.token
        or os.environ.get("GIT_TOKEN")
        or os.environ.get("GITHUB_TOKEN")
        or os.environ.get("GITLAB_TOKEN")
        or os.environ.get("BITBUCKET_TOKEN")
    )

    use_url = remote
    if token and remote.startswith("http"):
        use_url = inject_basic_auth(remote, args.username, token)

    branch = args.branch or unique_branch_name(args.prefix)

    print(f"Remote: {mask_token_in_url(remote)}")
    print(f"Branch: {branch}")

    with tempfile.TemporaryDirectory(prefix="repo-access-") as tmp:
        clone_dir = os.path.join(tmp, "repo")
        print("Cloning...")
        run(["git", "clone", "--origin", "origin", use_url, clone_dir])

        # Create a new branch from whatever HEAD is checked out after clone.
        print("Creating test branch and commit...")
        run(["git", "checkout", "-b", branch], cwd=clone_dir)

        marker_path = os.path.join(clone_dir, ".access-check")
        with open(marker_path, "w", encoding="utf-8") as f:
            f.write(f"access-ok @ {datetime.now(timezone.utc).isoformat()}\n")

        run(["git", "add", ".access-check"], cwd=clone_dir)
        run(["git", "commit", "-m", f"chore: access validation {branch}"] , cwd=clone_dir)

        print("Pushing test branch...")
        run(["git", "push", "-u", "origin", branch], cwd=clone_dir)
        print("Push succeeded.")

        if args.cleanup:
            print("Cleaning up remote branch...")
            try:
                run(["git", "push", "origin", "--delete", branch], cwd=clone_dir)
                print("Remote branch deleted.")
            except Exception as e:
                print(f"Warning: failed to delete remote branch: {e}")

    print("Validation complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

