#!/usr/bin/env bash
# Removes the Claude and Astra worktrees created by setup-worktrees.sh.
# Does NOT delete the branches, only the worktree directories.
#
# Usage: scripts/cleanup-worktrees.sh [--force]
set -euo pipefail

FORCE_FLAG=""
if [ "${1:-}" = "--force" ]; then
  FORCE_FLAG="--force"
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_ROOT")"
PARENT_DIR="$(dirname "$REPO_ROOT")"

FAILED=0

for dir in "$PARENT_DIR/${REPO_NAME}-claude" "$PARENT_DIR/${REPO_NAME}-astra"; do
  if git -C "$REPO_ROOT" worktree list --porcelain | grep -Fxq "worktree $dir"; then
    echo "Removing worktree $dir"
    if ! git -C "$REPO_ROOT" worktree remove $FORCE_FLAG "$dir"; then
      echo "  FAILED to remove $dir (it may have uncommitted changes -- retry with --force)" >&2
      FAILED=1
    fi
  else
    echo "No worktree registered at $dir, skipping"
  fi
done

echo "Done. Branches were left intact; delete them manually with 'git branch -d <branch>' if no longer needed."

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
