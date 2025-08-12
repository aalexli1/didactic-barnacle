#!/usr/bin/env python3
import argparse
import os
import sys

# Allow running directly without installing the package
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from src.repo_access import can_read_repo, can_push_repo, self_test


def main():
    parser = argparse.ArgumentParser(description="Validate Git repository access using real git operations.")
    parser.add_argument("--repo-url", help="Repository URL or local path. If omitted, runs a self-test against a temporary local bare repo.")
    parser.add_argument("--check-push", action="store_true", help="Attempt to push a test branch (only allowed for local filesystem repos).")
    args = parser.parse_args()

    if not args.repo_url:
        res = self_test()
        print(res.message)
        return 0 if res.ok else 1

    read = can_read_repo(args.repo_url)
    print(read.message)
    if not read.ok:
        return 1

    if args.check_push:
        push = can_push_repo(args.repo_url)
        print(push.message)
        return 0 if push.ok else 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
